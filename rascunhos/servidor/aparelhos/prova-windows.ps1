# Ordem PLANO-2-F2-PROVA-WINDOWS — a prova do Windows (JV2.1b), do princípio ao fim, sem passos manuais.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File rascunhos/servidor/aparelhos/prova-windows.ps1 `
#       -Godot <Godot_v4.7.2-stable_win64_console.exe> [-SemExport] [-Saida <pasta>] [-Porta 8090] [-SegundosNaMesa 30]
#
# O que faz, por esta ordem (cada passo com a hora no procedimento.log):
#   1. importa o projecto e exporta o Windows (preset «Windows»: build/windows/Assimilacao.exe + .console.exe);
#      -SemExport salta este passo e usa o build/windows que lá estiver (o SHA-256 do .exe fica registado na mesma);
#   2. arranca a mesa de prova (mesa-prova.mjs, Mestre-bot, combate aberto) e espera «pronto-mesa-prova»;
#   3. arranca o Assimilacao.console.exe exportado, com os argumentos ENTRE ASPAS (o defeito da corrida de 24/11: o
#      Start-Process -ArgumentList junta os argumentos sem aspas e «--entrar-nome=Espadachim de Bancada» chegava
#      partido em três; o cliente mostrava «pronto» e nunca entrava). A linha de comando que o Windows de facto
#      recebeu é lida do Win32_Process e fica no log;
#   4. espera a linha «rede: ROOM_SNAPSHOT … plataforma=Windows» do cliente;
#   5. deixa o cliente na mesa SegundosNaMesa (30 s por omissão), a conferir de 5 em 5 s que o processo está vivo e
#      que a mesa não registou SAIU;
#   6. mata o cliente (o harness, por comando: Stop-Process -Force ao processo do jogo e depois ao invólucro de
#      consola), regista o instante da morte (UTC, o mesmo relógio da mesa, e local) e os exit codes;
#   7. espera o SAIU na mesa, pára a mesa e confere: ENTROU e SAIU com horas, SAIU − ENTROU ≥ SegundosNaMesa,
#      SAIU depois da morte, 0 erros de script;
#   8. normaliza todos os logs para UTF-8 (sem BOM; o que não for UTF-8 válido é lido como CP1252, a página da
#      consola do Windows), troca o caminho da máquina por <sede>/<casa> e escreve-os INTEIROS em -Saida.
#
# O exit code do guião é 0 se a prova passa e 1 se falha; a última linha do procedimento.log diz qual.
# Não muda o cliente nem o servidor: só os arranca. Só fichas fictícias de bancada.
param(
  [Parameter(Mandatory = $true)][string]$Godot,
  [string]$Saida = '',
  [int]$Porta = 8090,
  [int]$SegundosNaMesa = 30,
  [switch]$SemExport
)
$ErrorActionPreference = 'Stop'
$Raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$Sede = Split-Path $Raiz -Parent
$Casa = $env:USERPROFILE
if (-not $Saida) { $Saida = Join-Path $Raiz 'provas\ordem-plano-2-f2\windows\corrida-30s' }
$Tmp = Join-Path $Sede 'tmp\prova-windows'
New-Item -ItemType Directory -Force $Saida, $Tmp | Out-Null
Get-ChildItem $Tmp -File | Remove-Item -Force
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Utf8Estrito = New-Object System.Text.UTF8Encoding($false, $true)
$Cp1252 = [System.Text.Encoding]::GetEncoding(1252)
$Proc = Join-Path $Tmp 'procedimento.log'
$falhas = New-Object System.Collections.ArrayList

function Get-Utc { [DateTime]::UtcNow.ToString('HH:mm:ss.fff') }
function Get-Local { (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss.fffzzz') }
function Limpar-Caminhos([string]$t) {
  # <sede> = a pasta acima do repositório; <casa> = a pasta do utilizador (as duas com \ e com /).
  foreach ($par in @(@($Sede, '<sede>'), @($Casa, '<casa>'))) {
    foreach ($c in @($par[0], $par[0].Replace('\', '/'))) {
      $t = [regex]::Replace($t, [regex]::Escape($c), $par[1], 'IgnoreCase')
    }
  }
  return $t
}
function Escrever-Passo([string]$t) {
  $linha = Limpar-Caminhos ('[' + (Get-Utc) + ' UTC | ' + (Get-Local) + '] ' + $t)
  [IO.File]::AppendAllText($Proc, $linha + "`r`n", $Utf8)
  Write-Host $linha
}
function Falhar([string]$t) { [void]$falhas.Add($t); Escrever-Passo ('FALHA: ' + $t) }
function Ler-Partilhado([string]$f) {
  # Lê um log que outro processo ainda está a escrever (sem o trancar).
  if (-not (Test-Path $f)) { return '' }
  $fs = [IO.File]::Open($f, 'Open', 'Read', 'ReadWrite')
  try { $sr = New-Object IO.StreamReader($fs, $Utf8); return $sr.ReadToEnd() } finally { $fs.Dispose() }
}
function Normalizar-Para([string]$origem, [string]$destino) {
  # O log inteiro, sem filtro. UTF-8 válido fica como está (sem BOM); senão é a página da consola (CP1252).
  if (-not (Test-Path $origem)) { return 'ausente' }
  $b = [IO.File]::ReadAllBytes($origem)
  $ini = 0
  if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { $ini = 3 }
  try { $t = $Utf8Estrito.GetString($b, $ini, $b.Length - $ini); $cod = 'UTF-8' }
  catch { $t = $Cp1252.GetString($b, $ini, $b.Length - $ini); $cod = 'CP1252 -> UTF-8' }
  [IO.File]::WriteAllText($destino, (Limpar-Caminhos $t), $Utf8)
  return ('{0} ({1} bytes na origem)' -f $cod, $b.Length)
}
function Iniciar([string]$exe, [string[]]$argumentos, [string]$pasta, [string]$nome) {
  $o = Join-Path $Tmp ($nome + '.log'); $e = Join-Path $Tmp ($nome + '.err')
  $p = Start-Process -FilePath $exe -ArgumentList $argumentos -WorkingDirectory $pasta -NoNewWindow `
    -RedirectStandardOutput $o -RedirectStandardError $e -PassThru
  $null = $p.Handle  # sem isto o Windows PowerShell 5.1 perde o ExitCode
  return $p
}
function Linha-De-Comando([int]$id) {
  $w = Get-CimInstance Win32_Process -Filter "ProcessId=$id" -ErrorAction SilentlyContinue
  if ($w) { return $w.CommandLine } else { return '(processo já não existe)' }
}

$mesa = $null; $cli = $null
try {
  $head = (& git -C $Raiz rev-parse HEAD).Trim()
  Escrever-Passo "início da prova do Windows; repositório em $Raiz; HEAD $head"
  Escrever-Passo ('comando: powershell -NoProfile -ExecutionPolicy Bypass -File rascunhos/servidor/aparelhos/prova-windows.ps1 -Godot ' +
    (Split-Path $Godot -Leaf) + $(if ($SemExport) { ' -SemExport' } else { '' }) + " -Porta $Porta -SegundosNaMesa $SegundosNaMesa")
  $verGodot = (& $Godot --version 2>$null | Select-Object -Last 1)
  Escrever-Passo ("Godot: $verGodot; node: " + (& node --version) + '; ' + [Environment]::OSVersion.VersionString)
  $cliente = Join-Path $Raiz 'rascunhos\cliente'
  $exeDir = Join-Path $Raiz 'build\windows'
  $exe = Join-Path $exeDir 'Assimilacao.console.exe'

  # ---- 1. import + export ----
  if (-not $SemExport) {
    New-Item -ItemType Directory -Force $exeDir | Out-Null
    foreach ($passo in @(@('import', @('--headless', '--path', '.', '--import'), 600),
                         @('export-Windows', @('--headless', '--path', '.', '--export-release', 'Windows'), 900))) {
      Escrever-Passo ('comando: cd rascunhos/cliente && ' + (Split-Path $Godot -Leaf) + ' ' + ($passo[1] -join ' '))
      $g = Iniciar $Godot $passo[1] $cliente $passo[0]
      if (-not $g.WaitForExit($passo[2] * 1000)) { Stop-Process -Id $g.Id -Force; Falhar "$($passo[0]): passou de $($passo[2]) s" }
      $g.WaitForExit()
      Escrever-Passo "$($passo[0]): exit $($g.ExitCode)"
      if ($passo[0] -ne 'import' -and $g.ExitCode -ne 0) { Falhar "$($passo[0]) com exit $($g.ExitCode)" }
    }
    $e = Ler-Partilhado (Join-Path $Tmp 'export-Windows.log')
    if ($e -match 'SCRIPT ERROR|Parse Error') { Falhar 'erros de script no export' }
  } else {
    Escrever-Passo 'export saltado (-SemExport): usa o build/windows que já lá está'
  }
  if (-not (Test-Path $exe)) { throw "não há $exe" }
  foreach ($f in @('Assimilacao.exe', 'Assimilacao.console.exe')) {
    $fi = Get-Item (Join-Path $exeDir $f)
    Escrever-Passo ('{0}: {1} bytes, SHA-256 {2}, escrito {3:yyyy-MM-ddTHH:mm:ss}' -f $f, $fi.Length,
      (Get-FileHash $fi.FullName -Algorithm SHA256).Hash.ToLower(), $fi.LastWriteTime)
  }

  # ---- 2. a mesa ----
  $argsMesa = @('aparelhos/mesa-prova.mjs', "--porta=$Porta", '--host=127.0.0.1', '--pin=11223344', '--mestre-auto')
  Escrever-Passo ('comando: cd rascunhos/servidor && node ' + ($argsMesa -join ' '))
  $mesa = Iniciar 'node' $argsMesa (Join-Path $Raiz 'rascunhos\servidor') 'mesa'
  $mesaLog = Join-Path $Tmp 'mesa.log'
  $t0 = [Diagnostics.Stopwatch]::StartNew()
  while ($t0.Elapsed.TotalSeconds -lt 30 -and (Ler-Partilhado $mesaLog) -notmatch 'pronto-mesa-prova') {
    if ($mesa.HasExited) { throw "a mesa saiu com exit $($mesa.ExitCode) antes de ficar pronta" }
    Start-Sleep -Milliseconds 100
  }
  if ((Ler-Partilhado $mesaLog) -notmatch 'pronto-mesa-prova') { throw 'a mesa não ficou pronta em 30 s' }
  Escrever-Passo "mesa pronta (pid $($mesa.Id)), combate aberto pelo Mestre-bot"

  # ---- 3. o cliente Windows, com os argumentos entre aspas ----
  $argsCli = @('--headless', '--', "--servidor=127.0.0.1:$Porta", '"--entrar-nome=Espadachim de Bancada"', '--entrar-senha=prova-espadachim')
  Escrever-Passo ('comando: Start-Process build/windows/Assimilacao.console.exe -ArgumentList ' + (($argsCli | ForEach-Object { "'" + $_ + "'" }) -join ','))
  $cli = Iniciar $exe $argsCli $exeDir 'windows'
  $tCli = [Diagnostics.Stopwatch]::StartNew()
  Start-Sleep -Milliseconds 300
  Escrever-Passo ("cliente arrancou: pid $($cli.Id); linha de comando recebida: " + (Linha-De-Comando $cli.Id))
  $filhos = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$($cli.Id)" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'Assimilacao*' })
  foreach ($f in $filhos) { Escrever-Passo ("processo do jogo (filho do invólucro de consola): pid $($f.ProcessId) $($f.Name); linha de comando: " + $f.CommandLine) }

  # ---- 4. o ROOM_SNAPSHOT ----
  $cliLog = Join-Path $Tmp 'windows.log'
  $padrao = 'rede: ROOM_SNAPSHOT seq=\d+ fase=combate plataforma=Windows'
  while ($tCli.Elapsed.TotalSeconds -lt 60 -and (Ler-Partilhado $cliLog) -notmatch $padrao) {
    if ($cli.HasExited) { break }
    Start-Sleep -Milliseconds 100
  }
  $m = [regex]::Match((Ler-Partilhado $cliLog), $padrao)
  if (-not $m.Success) { throw 'o cliente Windows não recebeu o ROOM_SNAPSHOT em 60 s' }
  $snapUtc = Get-Utc
  Escrever-Passo ('ROOM_SNAPSHOT recebido: «{0}», {1:N1} s depois de arrancar o cliente' -f $m.Value, $tCli.Elapsed.TotalSeconds)

  # ---- 5. 30 s na mesa ----
  Escrever-Passo "o cliente fica $SegundosNaMesa s na mesa (conferido de 5 em 5 s)"
  $tMesa = [Diagnostics.Stopwatch]::StartNew()
  $proxima = 5
  while ($tMesa.Elapsed.TotalSeconds -lt $SegundosNaMesa) {
    Start-Sleep -Milliseconds 100
    if ($cli.HasExited) { Falhar ('o cliente saiu sozinho {0:N1} s depois do snapshot (exit {1})' -f $tMesa.Elapsed.TotalSeconds, $cli.ExitCode); break }
    if ((Ler-Partilhado $mesaLog) -match 'SAIU Espadachim') { Falhar ('a mesa registou SAIU {0:N1} s depois do snapshot, antes da morte' -f $tMesa.Elapsed.TotalSeconds); break }
    if ($tMesa.Elapsed.TotalSeconds -ge $proxima) {
      $vivos = @($filhos | Where-Object { Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue }).Count
      Escrever-Passo ("+$proxima s: invólucro vivo (pid $($cli.Id)), processos do jogo vivos: $vivos de $($filhos.Count); a mesa sem SAIU")
      $proxima += 5
    }
  }

  # ---- 6. a morte, pelo harness ----
  if (-not $cli.HasExited) {
    $alvos = @($filhos | ForEach-Object { $_.ProcessId }) + @($cli.Id)
    $morteUtc = Get-Utc
    Escrever-Passo ("MORTE: o harness mata o cliente por comando (Stop-Process -Force), pids " + ($alvos -join ', ') +
      ('; {0:N3} s depois do snapshot; instante UTC {1}' -f $tMesa.Elapsed.TotalSeconds, $morteUtc))
    foreach ($id in $alvos) {
      $pp = Get-Process -Id $id -ErrorAction SilentlyContinue
      if ($pp) { Stop-Process -Id $id -Force; Escrever-Passo "Stop-Process -Id $id -Force feito" }
      else { Escrever-Passo "pid $id já tinha saído (o invólucro sai quando o jogo morre)" }
    }
    $cli.WaitForExit(10000) | Out-Null
    Escrever-Passo ("o invólucro de consola saiu: exit $($cli.ExitCode) (" + ('0x{0:X8}' -f $cli.ExitCode) + ')')
  }

  # ---- 7. o SAIU na mesa e as conferências ----
  $t1 = [Diagnostics.Stopwatch]::StartNew()
  while ($t1.Elapsed.TotalSeconds -lt 10 -and (Ler-Partilhado $mesaLog) -notmatch 'SAIU Espadachim') { Start-Sleep -Milliseconds 100 }
  $ml = Ler-Partilhado $mesaLog
  $en = [regex]::Match($ml, '(\d\d:\d\d:\d\d\.\d\d\d) ENTROU Espadachim de Bancada')
  $sa = [regex]::Match($ml, '(\d\d:\d\d:\d\d\.\d\d\d) SAIU Espadachim de Bancada')
  if (-not $en.Success) { Falhar 'a mesa não registou o ENTROU da Espadachim' }
  if (-not $sa.Success) { Falhar 'a mesa não registou o SAIU da Espadachim' }
  if ($en.Success -and $sa.Success) {
    $hE = [TimeSpan]::Parse($en.Groups[1].Value); $hS = [TimeSpan]::Parse($sa.Groups[1].Value)
    $na = ($hS - $hE).TotalSeconds
    Escrever-Passo ('na mesa (relógio da mesa, UTC): ENTROU {0} -> SAIU {1} = {2:N3} s; snapshot visto {3}; morte {4}' -f
      $en.Groups[1].Value, $sa.Groups[1].Value, $na, $snapUtc, $morteUtc)
    if ($na -lt $SegundosNaMesa) { Falhar ('a sessão durou {0:N3} s, menos de {1} s' -f $na, $SegundosNaMesa) }
    if ($morteUtc -and $hS -lt [TimeSpan]::Parse($morteUtc)) { Falhar 'o SAIU é anterior à morte: o cliente saiu sozinho' }
    if ($morteUtc) { Escrever-Passo ('SAIU {0:N3} s depois da morte' -f ($hS - [TimeSpan]::Parse($morteUtc)).TotalSeconds) }
  }
  $cl = Ler-Partilhado $cliLog
  $erros = ([regex]::Matches($cl + (Ler-Partilhado (Join-Path $Tmp 'windows.err')), 'SCRIPT ERROR|Parse Error|Compile Error')).Count
  Escrever-Passo "erros de script no cliente: $erros"
  if ($erros -gt 0) { Falhar "$erros erros de script no cliente" }
}
catch { Falhar ($_.Exception.Message) }
finally {
  if ($cli -and -not $cli.HasExited) { Stop-Process -Id $cli.Id -Force -ErrorAction SilentlyContinue }
  if ($mesa -and -not $mesa.HasExited) {
    Stop-Process -Id $mesa.Id -Force -ErrorAction SilentlyContinue; $mesa.WaitForExit(5000) | Out-Null
    Escrever-Passo "mesa parada pelo harness (Stop-Process -Force, pid $($mesa.Id)): exit $($mesa.ExitCode)"
  }
  # ---- 8. os logs, inteiros e em UTF-8 ----
  foreach ($n in @('import.log', 'import.err', 'export-Windows.log', 'export-Windows.err', 'mesa.log', 'mesa.err', 'windows.log', 'windows.err')) {
    $o = Join-Path $Tmp $n
    if (Test-Path $o) { Escrever-Passo ("log $n -> " + (Normalizar-Para $o (Join-Path $Saida $n))) }
  }
  if ($falhas.Count -eq 0) { Escrever-Passo 'PROVA WINDOWS OK; exit 0'; $codigo = 0 }
  else { Escrever-Passo ("PROVA WINDOWS FALHOU ($($falhas.Count) falhas); exit 1"); $codigo = 1 }
  Copy-Item $Proc (Join-Path $Saida 'procedimento.log') -Force
}
exit $codigo
