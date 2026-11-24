# ORDEM-CORR10-PREP - a bancada de rede verdadeira, num passo.
#
#   correr-com-o-mestre.cmd  [-Aliada] [-SoLobby] [-Motor auto|real|falso] [-Modo manual|semi|auto] [-Fichas canario|acertam]
#                            [-Porta 8790] [-HostServidor 0.0.0.0] [-Godot <exe>]
#
# 1. pára a bancada anterior (se ficou alguma) e arquiva os registos dela em privado\anteriores\<data>\;
# 2. prepara o arranque de PRODUCAO do servidor (preparar.mjs -> privado\config.json);
# 3. importa o projecto do cliente se ainda nao foi importado (--headless --import, uma vez);
# 4. levanta o SERVIDOR DO JOGO: node rascunhos\servidor\adaptadores\node\servidor-ws.js privado\config.json;
# 5. o PORTEIRO entra na sala com as credenciais de cada lugar, prepara a batalha (sem -SoLobby) e deixa o lugar no
#    user:// de cada cliente;
# 6. abre os CLIENTES GODOT VERDADEIROS (o projecto do cliente, cena principal, com janela), lado a lado: a Jogadora
#    (Heroina Teste) e o Mestre; com -Aliada, uma segunda jogadora. Cada cliente tem o seu APPDATA (o seu user://),
#    para dois clientes no mesmo PC nao partilharem o lugar.cfg. Todos ligam a ws://127.0.0.1:<porta>/ws;
# 7. fica a mostrar o registo do servidor; Enter (ou parar-bancada.cmd) fecha tudo.
# Nada do jogo muda: so se escrevem ficheiros em bancada-rede\privado\ (fora do Git).
param(
  [int]$Porta = 8790,
  [string]$HostServidor = '0.0.0.0',
  [ValidateSet('auto', 'real', 'falso')][string]$Motor = 'auto',
  [ValidateSet('manual', 'semi', 'auto')][string]$Modo = 'manual',
  [ValidateSet('canario', 'acertam')][string]$Fichas = 'canario',
  [switch]$Aliada,
  [switch]$SoLobby,
  [string]$Godot = '',
  [switch]$SemEspera
)
$ErrorActionPreference = 'Stop'
$Bancada = $PSScriptRoot
$Repo = Split-Path -Parent $Bancada
$Cliente = Join-Path $Repo 'rascunhos\cliente'
$Servidor = Join-Path $Repo 'rascunhos\servidor'
$Privado = Join-Path $Bancada 'privado'
$Reg = Join-Path $Privado 'registos'
$Pids = Join-Path $Privado 'pids.txt'

function Diz([string]$t) { Write-Host "[bancada] $t" }
function Falha([string]$t) { Write-Host "[bancada] FALHA: $t" -ForegroundColor Red; if (-not $SemEspera) { Read-Host 'Enter para sair' | Out-Null }; exit 1 }

# ---------------------------------------------------------------- ferramentas
$node = (Get-Command node -ErrorAction SilentlyContinue)
if ($null -eq $node) { Falha 'nao encontro o node (Node 18 ou mais) no PATH' }
if ($Godot -eq '') { $Godot = $env:GODOT }
if ($Godot -eq '' -or $null -eq $Godot) {
  foreach ($c in @('C:\Users\txcga\godot-472\Godot_v4.7.2-stable_win64.exe', 'C:\Users\txcga\godot-472\Godot_v4.7.2-stable_win64_console.exe')) {
    if (Test-Path $c) { $Godot = $c; break }
  }
}
if ($Godot -eq '' -or -not (Test-Path $Godot)) { Falha 'nao encontro o Godot 4.7.2 (use -Godot <exe> ou a variavel GODOT)' }

# ---------------------------------------------------------------- 1. a bancada anterior
function Parar-Anterior {
  if (Test-Path $Pids) {
    foreach ($l in Get-Content $Pids) {
      if ($l -match '^\d+$') { try { Stop-Process -Id ([int]$l) -Force -ErrorAction Stop } catch {} }
    }
    Remove-Item $Pids -Force
  }
}
Parar-Anterior
New-Item -ItemType Directory -Force $Privado | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$antigos = @()
if (Test-Path $Reg) { $antigos += $Reg }
$journal = Join-Path $Privado 'registo-MESTRE-ONLY-bancada-rede.json'
foreach ($f in @($journal, (Join-Path $Privado 'registo-MESTRE-ONLY-bancada-rede.alertas.json'))) { if (Test-Path $f) { $antigos += $f } }
Get-ChildItem $Privado -Filter 'registo-MESTRE-ONLY-bancada-rede*' -ErrorAction SilentlyContinue | ForEach-Object { if ($antigos -notcontains $_.FullName) { $antigos += $_.FullName } }
if ($antigos.Count -gt 0) {
  $dest = Join-Path $Privado "anteriores\$stamp"
  New-Item -ItemType Directory -Force $dest | Out-Null
  foreach ($a in $antigos) { Move-Item $a $dest -Force }
  Diz "registos da corrida anterior arquivados em privado\anteriores\$stamp"
}
New-Item -ItemType Directory -Force $Reg | Out-Null

# ---------------------------------------------------------------- 2. o arranque do servidor
$argsPrep = @("`"$Bancada\preparar.mjs`"", "--privado=`"$Privado`"", "--porta=$Porta", "--host=$HostServidor", "--motor=$Motor", "--modo=$Modo", "--fichas=$Fichas")
if ($Aliada) { $argsPrep += '--aliada' }
$prep = & node @argsPrep 2>&1
if ($LASTEXITCODE -ne 0) { Falha "preparar.mjs: $prep" }
$resumo = ($prep | Select-Object -Last 1) | ConvertFrom-Json
Diz "motor: $($resumo.motor) | fichas: $($resumo.fichas)"
$prep | Out-File -Encoding utf8 (Join-Path $Reg 'preparar.log')

# ---------------------------------------------------------------- 3. o import do cliente (uma vez)
if (-not (Test-Path (Join-Path $Cliente '.godot\imported'))) {
  Diz 'primeira vez: a importar o projecto do cliente (pode levar um minuto)...'
  $imp = Start-Process -FilePath $Godot -ArgumentList @('--headless', '--path', "`"$Cliente`"", '--import') -PassThru -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $Reg 'import.log') -RedirectStandardError (Join-Path $Reg 'import-erros.log')
  if (-not $imp.WaitForExit(600000)) { try { $imp.Kill() } catch {}; Falha 'o import do cliente passou de 10 minutos' }
}

# ---------------------------------------------------------------- 4. o servidor do jogo
$logSrv = Join-Path $Reg 'servidor.log'
$logSrvErr = Join-Path $Reg 'servidor-erros.log'
$srv = Start-Process -FilePath $node.Source -WorkingDirectory $Servidor -PassThru -WindowStyle Hidden `
  -ArgumentList @("`"$Servidor\adaptadores\node\servidor-ws.js`"", "`"$Privado\config.json`"") `
  -RedirectStandardOutput $logSrv -RedirectStandardError $logSrvErr
$srv.Id | Out-File -Encoding ascii $Pids
$t0 = Get-Date
while ($true) {
  Start-Sleep -Milliseconds 200
  if ($srv.HasExited) { Falha "o servidor saiu (codigo $($srv.ExitCode)): $(Get-Content $logSrvErr -Raw)" }
  if ((Test-Path $logSrv) -and (Select-String -Path $logSrv -Pattern 'servidor de mesa pronto' -Quiet)) { break }
  if (((Get-Date) - $t0).TotalSeconds -gt 30) { Falha 'o servidor nao ficou pronto em 30 s' }
}
Diz "servidor do jogo de pe na porta $Porta (host $HostServidor)"

# ---------------------------------------------------------------- 5. o porteiro
$projecto = Get-Content -Encoding UTF8 (Join-Path $Cliente 'project.godot') -Raw
$nomeApp = [regex]::Match($projecto, 'config/name="([^"]*)"').Groups[1].Value
$nomesJog = @((Get-Content -Encoding UTF8 (Join-Path $Privado 'config.json') -Raw | ConvertFrom-Json).sala.lugares | Where-Object { $_.papel -eq 'jogadora' } | ForEach-Object { $_.nome })
$clientes = @(
  @{ chave = 'jogadora'; rotulo = "Jogadora ($($nomesJog[0]))" },
  @{ chave = 'mestre'; rotulo = 'Mestre' }
)
if ($Aliada) { $clientes = @($clientes[0], @{ chave = 'aliada'; rotulo = "Jogadora ($($nomesJog[1]))" }, $clientes[1]) }
$argsPort = @("`"$Bancada\porteiro.mjs`"", "--config=`"$Privado\config.json`"")
foreach ($c in $clientes) {
  $c.appdata = Join-Path $Privado "clientes\$($c.chave)\AppData"
  $c.userdir = Join-Path $c.appdata "Godot\app_userdata\$nomeApp"
  New-Item -ItemType Directory -Force $c.appdata | Out-Null
  $argsPort += "--$($c.chave)=`"$($c.userdir)`""
}
if ($SoLobby) { $argsPort += '--so-lobby' }
$logPort = Join-Path $Reg 'porteiro.log'
$port = Start-Process -FilePath $node.Source -WorkingDirectory $Bancada -PassThru -WindowStyle Hidden -ArgumentList $argsPort `
  -RedirectStandardOutput $logPort -RedirectStandardError (Join-Path $Reg 'porteiro-erros.log')
$port.Id | Out-File -Encoding ascii -Append $Pids
$t0 = Get-Date
while ($true) {
  Start-Sleep -Milliseconds 200
  if ((Test-Path $logPort) -and (Select-String -Path $logPort -Pattern 'pronto-porteiro' -Quiet)) { break }
  if ($port.HasExited) { Falha "o porteiro saiu sem deixar os lugares: $(Get-Content (Join-Path $Reg 'porteiro-erros.log') -Raw)" }
  if (((Get-Date) - $t0).TotalSeconds -gt 90) { Falha 'o porteiro nao acabou em 90 s' }
}
Get-Content $logPort | ForEach-Object { Write-Host $_ }

# ---------------------------------------------------------------- 6. os clientes Godot, lado a lado
Add-Type -AssemblyName System.Windows.Forms
Add-Type -Namespace Bancada -Name Dpi -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();' -ErrorAction SilentlyContinue
try { [Bancada.Dpi]::SetProcessDPIAware() | Out-Null } catch {}
$area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$barra = 32  # a barra de titulo do Windows fica por cima da posicao dada
$n = $clientes.Count
if ($n -eq 2) {
  $w = [math]::Floor($area.Width / 2); $h = [math]::Min([math]::Floor($w * 9 / 16), $area.Height - $barra)
  $clientes[0].pos = @($area.X, ($area.Y + $barra)); $clientes[1].pos = @(($area.X + $w), ($area.Y + $barra))
  foreach ($c in $clientes) { $c.tam = @($w, $h) }
} else {
  # duas jogadoras empilhadas a esquerda, o Mestre a direita
  $w = [math]::Floor($area.Width / 2); $hj = [math]::Floor(($area.Height - 2 * $barra) / 2)
  $clientes[0].pos = @($area.X, ($area.Y + $barra)); $clientes[0].tam = @($w, $hj)
  $clientes[1].pos = @($area.X, ($area.Y + 2 * $barra + $hj)); $clientes[1].tam = @($w, $hj)
  $clientes[2].pos = @(($area.X + $w), ($area.Y + $barra)); $clientes[2].tam = @($w, [math]::Min([math]::Floor($w * 9 / 16), $area.Height - $barra))
}
$appdataOriginal = $env:APPDATA
foreach ($c in $clientes) {
  $env:APPDATA = $c.appdata  # o user:// deste cliente: <APPDATA>\Godot\app_userdata\<nome do projecto>
  $a = @('--path', "`"$Cliente`"", '--windowed', '--resolution', "$($c.tam[0])x$($c.tam[1])", '--position', "$($c.pos[0]),$($c.pos[1])",
    '--', "--servidor=127.0.0.1:$Porta")
  $p = Start-Process -FilePath $Godot -ArgumentList $a -PassThru -WorkingDirectory $Cliente
  $p.Id | Out-File -Encoding ascii -Append $Pids
  $c.proc = $p
  Diz "cliente Godot aberto: $($c.rotulo) (pid $($p.Id))"
  Start-Sleep -Milliseconds 400
}
$env:APPDATA = $appdataOriginal

# ---------------------------------------------------------------- 7. o painel
$ips = @()
try { $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop | Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } | ForEach-Object { $_.IPAddress } } catch {}
Write-Host ''
Write-Host '================ BANCADA DE REDE DE PE ================' -ForegroundColor Green
Write-Host " sala: $($resumo.porta) / sala-bancada-rede  - grelha-mapa da linha (50 x 50 casas de 1,5 m)"
Write-Host " clientes: $(($clientes | ForEach-Object { $_.rotulo }) -join ' + ')"
if ($HostServidor -eq '0.0.0.0' -and $ips.Count -gt 0) { Write-Host " na rede local: ws://$($ips[0]):$Porta/ws  (outros aparelhos: --servidor=$($ips[0]):$Porta)" }
Write-Host " registos: bancada-rede\privado\registos\  (o user:// de cada cliente: privado\clientes\<lugar>\)"
Write-Host ' Enter aqui (ou parar-bancada.cmd) fecha o servidor e os clientes.'
Write-Host '========================================================' -ForegroundColor Green
if ($SemEspera) { exit 0 }
Write-Host ''
$visto = 0
while ($true) {
  if ([Console]::KeyAvailable) {
    $k = [Console]::ReadKey($true)
    if ($k.Key -eq 'Enter') { break }
  }
  if (Test-Path $logSrv) {
    $linhas = @(Get-Content $logSrv)
    if ($linhas.Count -gt $visto) { $linhas[$visto..($linhas.Count - 1)] | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }; $visto = $linhas.Count }
  }
  if ($srv.HasExited) { Write-Host "[bancada] o servidor saiu (codigo $($srv.ExitCode))" -ForegroundColor Red; break }
  Start-Sleep -Milliseconds 300
}
Parar-Anterior
Diz 'bancada parada.'
