$script:R='<JV>\ordem-plano-2-f1-fecho-video-pc'
$script:CAP="$R\tmp\cap3"
$pids = Get-Content "$R\repo\bancada-rede\privado\pids.txt" | ? { $_ -match '^\d+$' }
$gs = @($pids | % { Get-Process -Id ([int]$_) -ErrorAction SilentlyContinue } | ? { $_.ProcessName -like 'Godot*' })
$script:J = JanelaDe $gs[0].Id; $script:M = JanelaDe $gs[$gs.Count - 1].Id
function script:Por($h, [int]$cx, [int]$cy, [int]$cw, [int]$ch) {
  $wr = New-Object U+RECT; [U]::GetWindowRect($h, [ref]$wr) | Out-Null; $c = Cliente $h
  $dl = $c.x - $wr.L; $dt = $c.y - $wr.T; $dr = ($wr.R - $wr.L) - $c.w - $dl; $db = ($wr.B - $wr.T) - $c.h - $dt
  [U]::SetWindowPos($h, [IntPtr]::Zero, $cx - $dl, $cy - $dt, $cw + $dl + $dr, $ch + $dt + $db, 0x0014) | Out-Null
}
Por $J -1892 51 1280 720
Por $M 0 51 1600 900
Start-Sleep -Milliseconds 1500
$vb = [System.Windows.Forms.SystemInformation]::VirtualScreen
"J=$J pid $($gs[0].Id) $((Cliente $J)|ConvertTo-Json -Compress)"
"M=$M pid $($gs[-1].Id) $((Cliente $M)|ConvertTo-Json -Compress)"
"virtual: $vb"
[System.Windows.Forms.Screen]::AllScreens | % { "ecra $($_.DeviceName) $($_.Bounds)" }
$script:vids = @{}
foreach ($k in @('jogadora','mestre')) {
  $h = if ($k -eq 'jogadora') { $J } else { $M }; $c = Cliente $h
  if ($c.x -lt $vb.X -or $c.y -lt $vb.Y -or ($c.x+$c.w) -gt ($vb.X+$vb.Width) -or ($c.y+$c.h) -gt ($vb.Y+$vb.Height)) { "AREA FORA DO ECRA $k"; continue }
  "area $k ($($c.x),$($c.y))-($($c.x+$c.w),$($c.y+$c.h)) dentro de ($($vb.X),$($vb.Y))-($($vb.X+$vb.Width),$($vb.Y+$vb.Height))"
  $fv = "$R\tmp\vid2\batalha-ponta-$k.mp4"
  $a = "-hide_banner -loglevel error -y -f gdigrab -framerate 30 -offset_x $($c.x) -offset_y $($c.y) -video_size $($c.w)x$($c.h) -draw_mouse 0 -i desktop -c:v libx264 -preset veryfast -crf 26 -pix_fmt yuv420p `"$fv`""
  $psi = New-Object System.Diagnostics.ProcessStartInfo "<JV>\ordem-plano-2-f1-pc\tmp\ffmpeg.exe", $a
  $psi.UseShellExecute = $false; $psi.RedirectStandardInput = $true; $psi.CreateNoWindow = $true
  $script:vids[$k] = [System.Diagnostics.Process]::Start($psi)
  "video $k $fv cmd: ffmpeg $a | pid $($script:vids[$k].Id) $(Get-Date -Format 'HH:mm:ss.fff')"
}
function script:VideosFim() { foreach ($k in @($script:vids.Keys)) { $p=$script:vids[$k]; $p.StandardInput.Write('q'); $p.StandardInput.Flush(); $p.WaitForExit(30000)|Out-Null; "fim $k saiu=$($p.HasExited) rc=$($p.ExitCode) $(Get-Date -Format 'HH:mm:ss.fff')" }; $script:vids=@{} }
function script:Cap([string]$n) { Captura $J "$CAP\$n-jog.png"; Captura $M "$CAP\$n-mestre.png" }
function script:Guarda([int]$min=120) { $i=[U]::Idle(); if ($i -lt $min) { throw "PC OCUPADO idle=$i - PARO" }; "idle=$i $(Get-Date -Format HH:mm:ss)" }
Start-Sleep 4
foreach ($k in $script:vids.Keys) { "$k vivo=$(-not $script:vids[$k].HasExited) bytes=$((Get-Item "$R\tmp\vid2\batalha-ponta-$k.mp4" -EA SilentlyContinue).Length)" }
Cap 'f2-a00-arranque'
function script:LinhasTexto() {
  $c = Cliente $J; $bmp = New-Object System.Drawing.Bitmap $c.w, $c.h
  $g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($c.x, $c.y, 0, 0, $bmp.Size); $g.Dispose()
  $rows = @(); for ($y = 150; $y -lt 560; $y++) { $n = 0; for ($x = 590; $x -lt 690; $x += 2) { $p = $bmp.GetPixel($x, $y); if ($p.R -gt 225 -and $p.G -gt 225 -and $p.B -gt 225) { $n++ } }; if ($n -ge 2) { $rows += $y } }
  $bmp.Dispose(); $cl = @(); $ini = -1; $ant = -10
  foreach ($y in $rows) { if ($y - $ant -gt 6) { if ($ini -ge 0) { $cl += ,@($ini, $ant) }; $ini = $y }; $ant = $y }
  if ($ini -ge 0) { $cl += ,@($ini, $ant) }; return ,$cl
}
function script:EncerrarSim() {
  Clicar $J 819 683; Start-Sleep -Milliseconds 1000
  $cl = LinhasTexto; $txt = ($cl | % { "$($_[0])-$($_[1])" }) -join ' '
  if ($cl.Count -ne 3) { return "DIALOGO? linhas=$txt" }
  $y = [int](($cl[1][0] + $cl[1][1]) / 2); Mover $J 640 $y; Start-Sleep -Milliseconds 150; Clicar $J 640 $y
  return "sim em y=$y (linhas $txt)"
}
function script:Medir([string]$n) { Start-Sleep -Milliseconds 1500; Captura $J "$CAP\$n-jog.png" | Out-Null; Captura $M "$CAP\$n-mestre.png" | Out-Null; "$n $(Get-Date -Format 'HH:mm:ss.fff') idle=$([U]::Idle())" }
"helpers ok"
