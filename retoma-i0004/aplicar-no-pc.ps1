<#
aplicar-no-pc.ps1 - I0004, 08/11/2026. Poe o original do PC igual ao ramo i0004/ci4-protocolo.

So copia ficheiros e confere SHA-256. Nao corre codigo do jogo (os testes ja correram no CI).
Por defeito e um ENSAIO: confere tudo e nao escreve nada. Para copiar, correr com -Aplicar.

  powershell -ExecutionPolicy Bypass -File .\retoma-i0004\aplicar-no-pc.ps1
  powershell -ExecutionPolicy Bypass -File .\retoma-i0004\aplicar-no-pc.ps1 -Aplicar

Para se:
  - o clone nao bater com depois.txt;
  - algum dos 13 ficheiros a substituir no PC ja nao for o do 9cbaca8 (antes.txt);
  - algum ficheiro novo ja existir no PC com outro conteudo.
Nesses casos NAO copia nada: avisar o Muse (CM-000009).
#>
param(
  [string]$Clone = (Split-Path -Parent $PSScriptRoot),
  [string]$Original = 'C:\Users\txcga\RPG_Local\jogo-verdadeiro',
  [switch]$Aplicar
)
$ErrorActionPreference = 'Stop'

function Sha([string]$p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLower() }
function Ler([string]$f) {
  $r = @()
  foreach ($l in Get-Content -LiteralPath $f -Encoding UTF8) {
    if ($l -match '^[0-9a-f]{64}  ') { $r += ,@($l.Substring(0, 64), $l.Substring(66)) }
  }
  return ,$r
}
function Caminho([string]$base, [string]$rel) { Join-Path $base ($rel -replace '/', '\') }

$antes = Ler (Join-Path $PSScriptRoot 'antes.txt')
$depois = Ler (Join-Path $PSScriptRoot 'depois.txt')
$substituir = @{}
foreach ($par in $antes) { $substituir[$par[1]] = $par[0] }
Write-Host ("Clone: {0}" -f $Clone)
Write-Host ("Original: {0}" -f $Original)
Write-Host ("{0} a substituir, {1} no total" -f $antes.Count, $depois.Count)

$erros = 0
# 1. O clone tem exactamente os ficheiros do ramo.
foreach ($par in $depois) {
  $p = Caminho $Clone $par[1]
  if (-not (Test-Path -LiteralPath $p) -or (Sha $p) -ne $par[0]) { Write-Host ("CLONE DIFERENTE: {0}" -f $par[1]); $erros++ }
}
if ($erros -gt 0) { throw 'PARAR: o clone nao bate com depois.txt.' }

# 2. O original do PC ainda esta no 9cbaca8 (os que mudam) e os novos nao existem com outro conteudo.
foreach ($par in $depois) {
  $p = Caminho $Original $par[1]
  $existe = Test-Path -LiteralPath $p
  if ($substituir.ContainsKey($par[1])) {
    if (-not $existe) { Write-Host ("FALTA NO PC: {0}" -f $par[1]); $erros++ }
    elseif ((Sha $p) -ne $substituir[$par[1]]) {
      if ((Sha $p) -eq $par[0]) { Write-Host ("JA IGUAL AO RAMO: {0}" -f $par[1]) }
      else { Write-Host ("PC DIFERENTE DO 9cbaca8: {0}" -f $par[1]); $erros++ }
    }
  } elseif ($existe -and (Sha $p) -ne $par[0]) {
    Write-Host ("NOVO JA EXISTE NO PC COM OUTRO CONTEUDO: {0}" -f $par[1]); $erros++
  }
}
if ($erros -gt 0) { throw ("PARAR: {0} diferenca(s). Nao copiar; avisar o Muse." -f $erros) }

if (-not $Aplicar) { Write-Host 'ENSAIO OK: nada foi escrito. Correr de novo com -Aplicar para copiar.'; return }

# 3. Copia de seguranca dos 13 que vao ser substituidos.
$bk = '{0}-antes-i0004-{1}' -f $Original, (Get-Date -Format 'yyyyMMdd-HHmm')
foreach ($par in $antes) {
  $de = Caminho $Original $par[1]
  $para = Caminho $bk $par[1]
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $para) | Out-Null
  Copy-Item -LiteralPath $de -Destination $para -Force
}
Write-Host ("Copia de seguranca: {0}" -f $bk)

# 4. Copiar do clone para o original.
foreach ($par in $depois) {
  $de = Caminho $Clone $par[1]
  $para = Caminho $Original $par[1]
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $para) | Out-Null
  Copy-Item -LiteralPath $de -Destination $para -Force
}

# 5. Conferir depois de copiar.
foreach ($par in $depois) {
  if ((Sha (Caminho $Original $par[1])) -ne $par[0]) { Write-Host ("DEPOIS DE COPIAR, DIFERENTE: {0}" -f $par[1]); $erros++ }
}
if ($erros -gt 0) { throw 'ERRO: a copia nao confere. Repor a partir da copia de seguranca e avisar o Muse.' }
Write-Host ("FEITO: {0} ficheiros no PC iguais ao ramo (SHA conferido)." -f $depois.Count)
