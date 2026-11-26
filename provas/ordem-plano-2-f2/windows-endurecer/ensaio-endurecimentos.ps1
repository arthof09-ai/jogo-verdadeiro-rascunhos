# ORDEM-PLANO-2-F2-PROVA-WINDOWS-ENDURECER, passo 3: provar que cada endurecimento morde.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File provas/ordem-plano-2-f2/windows-endurecer/ensaio-endurecimentos.ps1 `
#       -Godot <Godot_v4.7.2-stable_win64_console.exe> [-SegundosNaMesa 5]
#
# Para cada uma das quatro condições, aplica UMA substituição de texto a uma CÓPIA DE TRABALHO do guião
# (rascunhos/servidor/aparelhos/prova-windows.ensaio.ps1, ao lado do verdadeiro, para o $PSScriptRoot ser o mesmo;
# apagada no fim de cada ensaio e nunca cometida) e corre-a. Não toca no jogo, no servidor nem no guião verdadeiro:
# a condição forçada vive só na cópia (um argumento a menos, um nome que não existe, um log apagado em <sede>/tmp).
#
#   import   o --import corre com --path pasta-que-nao-existe (o Godot sai com exit 1); o export corre como sempre;
#   filhos   o filtro dos processos do jogo procura «NaoExiste*» em vez de «Assimilacao*» ($filhos vazio);
#   log      o windows.err é apagado de <sede>/tmp/prova-windows antes do passo 8 (log em falta);
#   combate  a mesa arranca sem --mestre-auto (o Mestre-bot não abre o combate; a linha não chega ao log).
#
# Cada condição corre duas vezes: sobre o guião endurecido (o do working tree; tem de falhar com a FALHA própria
# da condição) e, como controlo, sobre o guião original da ORDEM-PLANO-2-F2-PROVA-WINDOWS (a3d0cbc), para ver o que
# ele fazia com a mesma condição. Saídas em ensaios/<condição>-<guião>/ e o resumo em ensaios/resumo.txt.
# Exit 0 se as quatro condições fazem o guião endurecido falhar com a FALHA esperada; 1 se alguma não morde.
#
# user:// limpo em todas as corridas: cada guião corre com APPDATA=<sede>/tmp/appdata-ensaio, onde só há uma cópia
# dos modelos de export do Godot 4.7.2 (o export precisa deles) e de onde o app_userdata é apagado antes de cada
# corrida. Sem isto, o lugar.cfg que uma corrida que entra deixa no APPDATA faz a seguinte tentar o seatToken velho
# (recusado pela mesa nova) em vez do --entrar-nome — o 1.º ensaio, de 26/11 11:37, deu assim um «não recebeu o
# ROOM_SNAPSHOT» a mais nas corridas endurecido, alternadas com as do original que entravam. O guião endurecido
# isola ainda o user:// do cliente por si (APPDATA próprio só para o .exe); o original não, daí este APPDATA do ensaio.
param(
  [Parameter(Mandatory = $true)][string]$Godot,
  [int]$SegundosNaMesa = 5
)
$ErrorActionPreference = 'Stop'
$Raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$Sede = Split-Path $Raiz -Parent
$Aparelhos = Join-Path $Raiz 'rascunhos\servidor\aparelhos'
$Copia = Join-Path $Aparelhos 'prova-windows.ensaio.ps1'
$Original = Join-Path $Sede 'tmp\prova-windows-original-a3d0cbc.ps1'
$Ensaios = Join-Path $PSScriptRoot 'ensaios'
$Utf8 = New-Object System.Text.UTF8Encoding($true)  # o guião tem BOM (o PowerShell 5.1 precisa dele para ler o UTF-8)
New-Item -ItemType Directory -Force $Ensaios, (Split-Path $Original) | Out-Null
$Resumo = Join-Path $Ensaios 'resumo.txt'
$AppEnsaio = Join-Path $Sede 'tmp\appdata-ensaio'
$Modelos = Join-Path $env:APPDATA 'Godot\export_templates\4.7.2.stable'
$ModelosEnsaio = Join-Path $AppEnsaio 'Godot\export_templates\4.7.2.stable'
if (-not (Test-Path (Join-Path $ModelosEnsaio 'version.txt'))) {
  New-Item -ItemType Directory -Force $ModelosEnsaio | Out-Null
  Copy-Item (Join-Path $Modelos '*') $ModelosEnsaio -Force
}
[IO.File]::WriteAllText($Resumo, '', $Utf8)
function Resumir([string]$t) { [IO.File]::AppendAllText($Resumo, $t + "`r`n", (New-Object System.Text.UTF8Encoding($false))); Write-Host $t }

# O guião original, byte a byte (o cmd redirige sem recodificar).
cmd /c "git -C `"$Raiz`" show a3d0cbc:rascunhos/servidor/aparelhos/prova-windows.ps1 > `"$Original`""
if ($LASTEXITCODE -ne 0) { throw 'git show a3d0cbc falhou' }
$guioes = [ordered]@{ endurecido = (Join-Path $Aparelhos 'prova-windows.ps1'); original = $Original }

# condição -> (texto a trocar, texto novo, -SemExport?, regex da FALHA esperada no guião endurecido)
$condicoes = [ordered]@{
  import  = @("@('--headless', '--path', '.', '--import')", "@('--headless', '--path', 'pasta-que-nao-existe', '--import')", $false,
              'FALHA: import com exit 1')
  filhos  = @("Where-Object { `$_.Name -like 'Assimilacao*' })", "Where-Object { `$_.Name -like 'NaoExiste*' })", $true,
              'FALHA: o invólucro de consola \(pid \d+\) não tem processo do jogo')
  log     = @("  # ---- 8. os logs", "  Remove-Item (Join-Path `$Tmp 'windows.err') -Force  # ENSAIO: log em falta`r`n  # ---- 8. os logs", $true,
              'FALHA: log windows\.err em falta')
  combate = @("'--pin=11223344', '--mestre-auto')", "'--pin=11223344')", $true,
              'FALHA: a mesa ficou pronta sem a linha «\[mesa-prova\] combate aberto pelo Mestre-bot»')
}

function Limpar-Restos {
  # Um controlo do guião original pode deixar o Assimilacao.exe órfão (ele só mata o invólucro): pára-o aqui.
  $exeDir = Join-Path $Raiz 'build\windows'
  $parados = @()
  foreach ($p in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.ExecutablePath -and $_.ExecutablePath.StartsWith($exeDir, 'OrdinalIgnoreCase') })) {
    Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
    $parados += ('pid {0} {1}' -f $p.ProcessId, $p.Name)
  }
  if ($parados.Count -eq 0) { return 'restos: nenhum' }
  return ('restos parados pelo ensaio: ' + ($parados -join ', '))
}

$naoMordeu = 0
Resumir ("ensaio dos endurecimentos; HEAD " + (& git -C $Raiz rev-parse HEAD).Trim() + "; -SegundosNaMesa $SegundosNaMesa; " + (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz'))
foreach ($c in $condicoes.Keys) {
  $de, $para, $semExport, $esperada = $condicoes[$c]
  foreach ($g in $guioes.Keys) {
    $texto = [IO.File]::ReadAllText($guioes[$g])
    $n = ([regex]::Matches($texto, [regex]::Escape($de))).Count
    if ($n -ne 1) { throw "condição $c, guião ${g}: o texto a trocar aparece $n vezes (tem de ser 1)" }
    [IO.File]::WriteAllText($Copia, $texto.Replace($de, $para), $Utf8)
    $saida = Join-Path $Ensaios "$c-$g"
    if (Test-Path $saida) { Remove-Item -Recurse -Force $saida }
    $argumentos = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Copia, '-Godot', $Godot, '-Saida', $saida, '-SegundosNaMesa', $SegundosNaMesa)
    if ($semExport) { $argumentos += '-SemExport' }
    $ud = Join-Path $AppEnsaio 'Godot\app_userdata'
    if (Test-Path $ud) { Remove-Item -Recurse -Force $ud }
    $appdataAntes = $env:APPDATA
    $env:APPDATA = $AppEnsaio
    try { & powershell @argumentos *> $null } finally { $env:APPDATA = $appdataAntes }
    $exit = $LASTEXITCODE
    Remove-Item -Force $Copia
    $restos = Limpar-Restos
    $proc = Get-Content -Encoding UTF8 (Join-Path $saida 'procedimento.log')
    $falhasVistas = @($proc | Where-Object { $_ -match 'FALHA: ' } | ForEach-Object { $_ -replace '^\[[^\]]*\] ', '' })
    $veredito = ($proc | Select-Object -Last 1) -replace '^\[[^\]]*\] ', ''
    $ml = Join-Path $saida 'mesa.log'
    $entrou = $(if ((Test-Path $ml) -and ((Get-Content -Raw -Encoding UTF8 $ml) -match 'ENTROU Espadachim')) { 'a Espadachim entrou na mesa' } else { 'a Espadachim não entrou na mesa' })
    $linha = "[$c / $g] exit $exit; $veredito; $entrou; $restos"
    if ($g -eq 'endurecido') {
      $mordeu = ($exit -eq 1) -and (@($falhasVistas | Where-Object { $_ -match $esperada }).Count -ge 1)
      if (-not $mordeu) { $naoMordeu++ }
      $linha += $(if ($mordeu) { '; MORDE (a FALHA esperada está lá)' } else { '; NÃO MORDE' })
    }
    Resumir $linha
    foreach ($f in $falhasVistas) { Resumir ("    " + $f) }
  }
}
Remove-Item -Force $Original
if ($naoMordeu -eq 0) { Resumir 'ENSAIO OK: as quatro condições fazem o guião endurecido falhar; exit 0'; exit 0 }
Resumir "ENSAIO FALHOU: $naoMordeu condição(ões) não mordem; exit 1"; exit 1
