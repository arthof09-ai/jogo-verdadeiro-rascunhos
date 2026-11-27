# ORDEM-PLANO-2-F1-F2-FECHO-4DEZ (B3) — a mesa do ensaio da casa (JV3.4b), num passo.
#
#   arrancar-ensaio.cmd  [-Web <pasta do export web>] [-Porta 8080] [-SemEspera]
#
# O que faz (nada do jogo muda; só escreve ficheiros em <sede>\ensaio-4dez-privado\, fora do Git):
#   1. prepara o arranque de PRODUÇÃO do servidor com a bancada de rede (bancada-rede/preparar.mjs): o VLAB real
#      (em cache depois da 1.ª vez), as fichas FICTÍCIAS «acertam» (a Arqueira de Bancada contra o Lobo e o Bruto de
#      Bancada), os monstros em modo auto, o journal ligado, host 0.0.0.0 (a rede da casa);
#   2. junta à config o export web («pastaEstatica», copiado para o disco local), a pasta das medições V1.0
#      («medicoes») e o QR («qr»: true) — a jogadora abre o jogo pelo QR, na MESMA origem do ws://…/ws;
#   3. levanta o servidor (node rascunhos/servidor/adaptadores/node/servidor-ws.js config.json);
#   4. o porteiro (bancada-rede/porteiro.mjs) entra como Mestre e prepara a batalha (lobby → início → as duas
#      criaturas em terra); depois sai, e a mesa fica à espera do Mestre (que entra no navegador do PC com o PIN);
#   5. mostra os links, o PIN e as senhas, e fica a mostrar o registo do servidor. Enter fecha tudo e guarda o journal,
#      o registo e as medições em <sede>\ensaio-4dez-privado\resultado-<data>\.
param(
  [string]$Web = '',
  [int]$Porta = 8080,
  [switch]$SemEspera
)
$ErrorActionPreference = 'Stop'
$Aqui = $PSScriptRoot
$Repo = (Resolve-Path (Join-Path $Aqui '..\..\..')).Path
$Sede = Split-Path $Repo -Parent
$Servidor = Join-Path $Repo 'rascunhos\servidor'
$Bancada = Join-Path $Repo 'bancada-rede'
$Privado = Join-Path $Sede 'ensaio-4dez-privado'
$Reg = Join-Path $Privado 'registos'
function Diz([string]$t) { Write-Host "[ensaio] $t" }
function Falha([string]$t) { Write-Host "[ensaio] FALHA: $t" -ForegroundColor Red; if (-not $SemEspera) { Read-Host 'Enter para sair' | Out-Null }; exit 1 }

$node = Get-Command node -ErrorAction SilentlyContinue
if ($null -eq $node) { Falha 'não encontro o node (Node 18 ou mais) no PATH' }
if ($Web -eq '') {
  foreach ($c in @((Join-Path $Repo 'build\web'), 'G:\Meu Drive\RPG Assimilação\13 — Trabalho das cadeiras\f1-f2-fecho-4dez\build-web')) {
    if (Test-Path (Join-Path $c 'index.html')) { $Web = $c; break }
  }
}
if ($Web -eq '' -or -not (Test-Path (Join-Path $Web 'index.html'))) { Falha 'não encontro o export web (use -Web <pasta com o index.html>)' }

# ---- 1. o arranque de produção (a corrida anterior fica arquivada)
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
New-Item -ItemType Directory -Force $Privado | Out-Null
foreach ($velho in @($Reg, (Join-Path $Privado 'registo-MESTRE-ONLY-bancada-rede.json'), (Join-Path $Privado 'medicoes'))) {
  if (Test-Path $velho) {
    $dest = Join-Path $Privado "anteriores\$stamp"; New-Item -ItemType Directory -Force $dest | Out-Null; Move-Item $velho $dest -Force
  }
}
Get-ChildItem $Privado -Filter 'registo-MESTRE-ONLY-bancada-rede*' -File -ErrorAction SilentlyContinue | ForEach-Object {
  $dest = Join-Path $Privado "anteriores\$stamp"; New-Item -ItemType Directory -Force $dest | Out-Null; Move-Item $_.FullName $dest -Force
}
New-Item -ItemType Directory -Force $Reg, (Join-Path $Privado 'medicoes') | Out-Null
$prep = & node (Join-Path $Bancada 'preparar.mjs') "--privado=$Privado" "--porta=$Porta" '--host=0.0.0.0' '--motor=real' '--modo=auto' '--fichas=acertam' 2>&1
if ($LASTEXITCODE -ne 0) { Falha "preparar.mjs: $prep" }
$prep | Out-File -Encoding utf8 (Join-Path $Reg 'preparar.log')
$resumo = ($prep | Select-Object -Last 1) | ConvertFrom-Json
Diz "motor: $($resumo.motor) | fichas: $($resumo.fichas) | porta $Porta"
if ($resumo.motor -notlike 'real*') { Falha "o motor não é o VLAB real ($($resumo.motor)): sem rede na 1.ª vez? Ligue a internet e repita." }

# ---- 2. o export web no disco local + medições + QR
$webLocal = Join-Path $Privado 'web'
if (Test-Path $webLocal) { Remove-Item -Recurse -Force $webLocal }
Copy-Item -Recurse $Web $webLocal
$cfgPath = Join-Path $Privado 'config.json'
& node -e "const f=require('fs');const p=process.argv[1];const c=JSON.parse(f.readFileSync(p,'utf8'));c.pastaEstatica='web';c.medicoes='medicoes';c.qr=true;f.writeFileSync(p,JSON.stringify(c,null,2));" $cfgPath
if ($LASTEXITCODE -ne 0) { Falha 'não consegui juntar o export web à config' }
$sha = (Get-FileHash (Join-Path $webLocal 'index.pck') -Algorithm SHA256).Hash.ToLower()
Diz "export web: $Web (index.pck SHA-256 $sha)"

# ---- 3. o servidor
$logSrv = Join-Path $Reg 'servidor.log'
$srv = Start-Process -FilePath $node.Source -WorkingDirectory $Servidor -PassThru -NoNewWindow `
  -ArgumentList @("`"$Servidor\adaptadores\node\servidor-ws.js`"", "`"$cfgPath`"") `
  -RedirectStandardOutput $logSrv -RedirectStandardError (Join-Path $Reg 'servidor-erros.log')
$srv.Id | Out-File -Encoding ascii (Join-Path $Privado 'pids.txt')
$t0 = Get-Date
while (-not ((Test-Path $logSrv) -and (Select-String -Path $logSrv -Pattern 'servidor de mesa pronto' -Quiet))) {
  Start-Sleep -Milliseconds 200
  if ($srv.HasExited) { Falha "o servidor saiu (código $($srv.ExitCode)): $(Get-Content (Join-Path $Reg 'servidor-erros.log') -Raw)" }
  if (((Get-Date) - $t0).TotalSeconds -gt 30) { Falha 'o servidor não ficou pronto em 30 s' }
}
Diz "servidor de pé (pid $($srv.Id))"

# ---- 4. o porteiro prepara a batalha e sai
$pm = Join-Path $Privado 'porteiro\mestre'; $pj = Join-Path $Privado 'porteiro\jogadora'
New-Item -ItemType Directory -Force $pm, $pj | Out-Null
& node (Join-Path $Bancada 'porteiro.mjs') "--config=$cfgPath" "--mestre=$pm" "--jogadora=$pj" '--espera-s=1' 2>&1 | ForEach-Object { "$_" } | Out-File -Encoding utf8 (Join-Path $Reg 'porteiro.log')
if ($LASTEXITCODE -ne 0) { Falha "o porteiro falhou: $(Get-Content (Join-Path $Reg 'porteiro.log') -Raw)" }
Remove-Item -Recurse -Force (Join-Path $Privado 'porteiro')  # o seatToken do porteiro não fica em disco
Diz 'batalha preparada (Arqueira de Bancada contra o Lobo e o Bruto de Bancada); a mesa espera o Mestre'

# ---- 5. os links e as credenciais
$cfg = Get-Content -Encoding UTF8 $cfgPath -Raw | ConvertFrom-Json
$arq = $cfg.sala.lugares | Where-Object { $_.papel -eq 'jogadora' } | Select-Object -First 1
$mes = $cfg.sala.lugares | Where-Object { $_.papel -eq 'mestre' } | Select-Object -First 1
Write-Host ''
Get-Content -Encoding UTF8 $logSrv | Select-String -Pattern 'http://' | ForEach-Object { Write-Host "  $($_.Line)" }
Write-Host "  QR grande no PC:  http://localhost:$Porta/qr"
Write-Host "  Mestre (no PC):   http://localhost:$Porta/   PIN $($mes.pin)"
Write-Host "  Celular:          nome «$($arq.nome)»  senha «$($arq.senha)»"
Write-Host ''
if ($SemEspera) { Diz "pronto-ensaio $Porta"; exit 0 }
Read-Host '[ensaio] a mesa está aberta. Enter AQUI (só no fim do ensaio) fecha a mesa e guarda o resultado' | Out-Null
Stop-Process -Id $srv.Id -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
$res = Join-Path $Privado "resultado-$stamp"
New-Item -ItemType Directory -Force $res | Out-Null
Copy-Item $Reg, (Join-Path $Privado 'medicoes') $res -Recurse -Force
Get-ChildItem $Privado -Filter 'registo-MESTRE-ONLY-bancada-rede*' -File | Copy-Item -Destination $res -Force
Diz "resultado guardado em $res"
Read-Host 'Enter para sair' | Out-Null
