# ORDEM-D-AUD-06-MARCADORES-CAIXA - uma corrida da bancada de rede, conduzida e sem janelas no ecra.
#
#   correr-bancada.ps1 -Cliente <rascunhos\cliente da arvore a provar> -Rotulo antes|depois -Saida <pasta>
#                      -Privado <pasta fora do Git> -Godot <exe> [-Orc 38,14] [-MoverPara x,y] [-OrcPara x,y]
#
# Os mesmos passos do bancada-rede\lancar.ps1 (preparar.mjs -> servidor de producao -> porteiro), com duas diferencas:
#   - o porteiro recebe --orc (a casa do orc-teste no lago);
#   - os dois clientes Godot (Jogadora 1280x720, Mestre 1600x900) correm a cena principal pelo condutor_bancada.gd
#     (-s), que carrega nos botoes e grava as capturas e as medidas. Neste PC o agente corre na sessao 0 (servico):
#     as janelas do Godot existem e desenham (GPU verdadeira), mas nao aparecem no ecra de quem esta sentado ao PC.
# O servidor e o porteiro sao os da arvore $Repo (a do trabalho); o cliente e o de -Cliente (antes ou depois).
param(
  [Parameter(Mandatory)][string]$Cliente,
  [Parameter(Mandatory)][string]$Rotulo,
  [Parameter(Mandatory)][string]$Saida,
  [Parameter(Mandatory)][string]$Privado,
  [Parameter(Mandatory)][string]$Godot,
  [string]$Orc = '38,14',
  [string]$MoverPara = '',
  [string]$OrcPara = '',
  [int]$Porta = 8790
)
$ErrorActionPreference = 'Stop'
$Ferr = $PSScriptRoot
$Repo = (Resolve-Path (Join-Path $Ferr '..\..\..')).Path
$Bancada = Join-Path $Repo 'bancada-rede'
$Servidor = Join-Path $Repo 'rascunhos\servidor'
$Condutor = Join-Path $Ferr 'condutor_bancada.gd'
$node = (Get-Command node).Source
New-Item -ItemType Directory -Force $Saida, $Privado | Out-Null
$Reg = Join-Path $Saida "registos-$Rotulo"
New-Item -ItemType Directory -Force $Reg | Out-Null
$procs = @()
function Diz([string]$t) { Write-Host "[corrida $Rotulo] $t" }
try {
  # 0. sem o journal da corrida anterior (o servidor restaurava-o: a sala voltava em pausa)
  Get-ChildItem $Privado -Filter 'registo-MESTRE-ONLY*' -ErrorAction SilentlyContinue | Remove-Item -Force
  # 1. a config do servidor (motor auto: o real se houver rede/cache, senao o falso dos testes)
  $prep = & $node "$Bancada\preparar.mjs" "--privado=$Privado" "--porta=$Porta" '--host=127.0.0.1' '--motor=auto' '--modo=manual' '--fichas=canario' 2>&1
  if ($LASTEXITCODE -ne 0) { throw "preparar.mjs: $prep" }
  $prep | Out-File -Encoding utf8 (Join-Path $Reg 'preparar.log')
  Diz "config: $(($prep | Select-Object -Last 1))"
  # 2. o servidor
  $logSrv = Join-Path $Reg 'servidor.log'
  $srv = Start-Process -FilePath $node -WorkingDirectory $Servidor -PassThru -WindowStyle Hidden `
    -ArgumentList @("`"$Servidor\adaptadores\node\servidor-ws.js`"", "`"$Privado\config.json`"") `
    -RedirectStandardOutput $logSrv -RedirectStandardError (Join-Path $Reg 'servidor-erros.log')
  $procs += $srv
  $t0 = Get-Date
  while (-not ((Test-Path $logSrv) -and (Select-String -Path $logSrv -Pattern 'servidor de mesa pronto' -Quiet))) {
    Start-Sleep -Milliseconds 200
    if ($srv.HasExited -or ((Get-Date) - $t0).TotalSeconds -gt 30) { throw 'o servidor nao ficou pronto' }
  }
  Diz 'servidor pronto'
  # 3. o porteiro (o lugar de cada cliente no user:// dele)
  $projecto = Get-Content -Encoding UTF8 (Join-Path $Cliente 'project.godot') -Raw
  $nomeApp = [regex]::Match($projecto, 'config/name="([^"]*)"').Groups[1].Value
  $cli = @{}
  foreach ($k in @('jogadora', 'mestre')) {
    $ad = Join-Path $Privado "c-$Rotulo-$(Get-Date -Format 'HHmmss')\$k\AppData"  # um user:// novo por corrida
    New-Item -ItemType Directory -Force $ad | Out-Null
    $cli[$k] = @{ appdata = $ad; userdir = (Join-Path $ad "Godot\app_userdata\$nomeApp") }
  }
  $logPort = Join-Path $Reg 'porteiro.log'
  $port = Start-Process -FilePath $node -WorkingDirectory $Bancada -PassThru -WindowStyle Hidden `
    -ArgumentList @("`"$Bancada\porteiro.mjs`"", "`"--config=$Privado\config.json`"", "`"--jogadora=$($cli.jogadora.userdir)`"",
      "`"--mestre=$($cli.mestre.userdir)`"", "--orc=$Orc") `
    -RedirectStandardOutput $logPort -RedirectStandardError (Join-Path $Reg 'porteiro-erros.log')
  $procs += $port
  $t0 = Get-Date
  while (-not ((Test-Path $logPort) -and (Select-String -Path $logPort -Pattern 'pronto-porteiro' -Quiet))) {
    Start-Sleep -Milliseconds 200
    if ($port.HasExited -or ((Get-Date) - $t0).TotalSeconds -gt 90) { throw "o porteiro falhou: $(Get-Content (Join-Path $Reg 'porteiro-erros.log') -Raw)" }
  }
  Diz 'porteiro pronto'
  # 4. os dois clientes, conduzidos
  $orig = $env:APPDATA
  $g = @{}
  foreach ($k in @('jogadora', 'mestre')) {
    $env:APPDATA = $cli[$k].appdata
    $res = if ($k -eq 'mestre') { '1600x900' } else { '1280x720' }
    $a = @('--path', "`"$Cliente`"", '--windowed', '--resolution', $res, '-s', "`"$Condutor`"", '--',
      "--servidor=127.0.0.1:$Porta", "--papel=$k", "`"--saida=$Saida`"", "--rotulo=$Rotulo")
    $a += "--janela=$res"
    if ($k -eq 'jogadora' -and $MoverPara -ne '') { $a += "--andar-antes=$MoverPara"; $a += '--exigir-ataque=1' }
    if ($k -eq 'mestre' -and $OrcPara -ne '') { $a += "--orc-para=$OrcPara" }
    $p = Start-Process -FilePath $Godot -ArgumentList $a -PassThru -WorkingDirectory $Cliente `
      -RedirectStandardOutput (Join-Path $Reg "godot-$k.log") -RedirectStandardError (Join-Path $Reg "godot-$k-erros.log")
    $g[$k] = $p
    $procs += $p
    Diz "cliente $k (pid $($p.Id), $res)"
    Start-Sleep -Milliseconds 1500
  }
  $env:APPDATA = $orig
  foreach ($k in @('mestre', 'jogadora')) {
    if (-not $g[$k].WaitForExit(400000)) { Diz "o cliente $k nao acabou em 400 s"; try { $g[$k].Kill() } catch {} }
    else { Diz "cliente $k acabou (codigo $($g[$k].ExitCode))" }
  }
} finally {
  foreach ($p in $procs) { try { if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force } } catch {} }
  Diz 'parado'
}
