# Agente da sessao 1 (ambiente de trabalho real): executa comandos deixados em tmp\cmd\*.ps1 (por ordem de nome),
# escreve a saida em tmp\cmd\<nome>.out e apaga o .ps1. Para com o ficheiro tmp\cmd\PARAR.
# Input so por PostMessage as janelas do Godot (nao mexe no cursor nem no teclado globais).
param([string]$pasta = 'cmd')
$ErrorActionPreference = 'Continue'
$sede = '<JV>\ordem-plano-2-f1-pc'
$cmdDir = "$sede\tmp\$pasta"
New-Item -ItemType Directory -Force $cmdDir | Out-Null
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class U {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc f, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool GetLastInputInfo(ref LASTINPUTINFO p);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint c, uint t);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [StructLayout(LayoutKind.Sequential)] public struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
  public static uint Idle() { LASTINPUTINFO i = new LASTINPUTINFO(); i.cbSize = 8; GetLastInputInfo(ref i); return ((uint)Environment.TickCount - i.dwTime) / 1000; }
}
"@
[U]::SetProcessDPIAware() | Out-Null

function JanelaDe([int]$procId) {
  $script:achada = [IntPtr]::Zero
  $cb = [U+EnumProc]{ param($h, $l) $p = 0; [U]::GetWindowThreadProcessId($h, [ref]$p) | Out-Null
    if ($p -eq $procId -and [U]::IsWindowVisible($h)) { $sb = New-Object System.Text.StringBuilder 256; [U]::GetWindowText($h, $sb, 256) | Out-Null
      if ($sb.Length -gt 0) { $script:achada = $h; return $false } }
    return $true }
  [U]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
  return $script:achada
}
function MkLp([int]$x, [int]$y) { return [IntPtr](($y -shl 16) -bor ($x -band 0xFFFF)) }
function Mover($h, [int]$x, [int]$y) { [U]::PostMessage($h, 0x0200, [IntPtr]0, (MkLp $x $y)) | Out-Null }
function Clicar($h, [int]$x, [int]$y, [int]$espera = 60) {
  Mover $h $x $y; Start-Sleep -Milliseconds 40
  [U]::PostMessage($h, 0x0201, [IntPtr]1, (MkLp $x $y)) | Out-Null; Start-Sleep -Milliseconds $espera
  [U]::PostMessage($h, 0x0202, [IntPtr]0, (MkLp $x $y)) | Out-Null
}
function ClicarDir($h, [int]$x, [int]$y) {
  Mover $h $x $y; Start-Sleep -Milliseconds 40
  [U]::PostMessage($h, 0x0204, [IntPtr]2, (MkLp $x $y)) | Out-Null; Start-Sleep -Milliseconds 60
  [U]::PostMessage($h, 0x0205, [IntPtr]0, (MkLp $x $y)) | Out-Null
}
function Arrastar($h, [int]$x0, [int]$y0, [int]$x1, [int]$y1, [int]$passos = 15, [int]$botao = 1) {
  $down = 0x0201; $up = 0x0202; $mk = 1
  if ($botao -eq 3) { $down = 0x0207; $up = 0x0208; $mk = 0x10 }
  if ($botao -eq 2) { $down = 0x0204; $up = 0x0205; $mk = 2 }
  Mover $h $x0 $y0; [U]::PostMessage($h, $down, [IntPtr]$mk, (MkLp $x0 $y0)) | Out-Null
  for ($i = 1; $i -le $passos; $i++) { $x = [int]($x0 + ($x1 - $x0) * $i / $passos); $y = [int]($y0 + ($y1 - $y0) * $i / $passos)
    [U]::PostMessage($h, 0x0200, [IntPtr]$mk, (MkLp $x $y)) | Out-Null; Start-Sleep -Milliseconds 30 }
  [U]::PostMessage($h, $up, [IntPtr]0, (MkLp $x1 $y1)) | Out-Null
}
function Roda($h, [int]$x, [int]$y, [int]$delta) {
  $p = New-Object U+POINT; $p.X = $x; $p.Y = $y; [U]::ClientToScreen($h, [ref]$p) | Out-Null
  $w = [IntPtr](($delta -band 0xFFFF) -shl 16)
  [U]::PostMessage($h, 0x020A, $w, (MkLp $p.X $p.Y)) | Out-Null
}
function Tecla($h, [int]$vk, [int]$seg = 0) {
  $sc = [U]::MapVirtualKey($vk, 0)
  [U]::PostMessage($h, 0x0100, [IntPtr]$vk, [IntPtr](1 -bor ($sc -shl 16))) | Out-Null
  if ($seg -gt 0) { Start-Sleep -Milliseconds $seg } else { Start-Sleep -Milliseconds 60 }
  [U]::PostMessage($h, 0x0101, [IntPtr]$vk, [IntPtr]((1 -bor ($sc -shl 16)) -bor 0xC0000000)) | Out-Null
}
function Cliente($h) {
  $r = New-Object U+RECT; [U]::GetClientRect($h, [ref]$r) | Out-Null
  $p = New-Object U+POINT; [U]::ClientToScreen($h, [ref]$p) | Out-Null
  return @{ x = $p.X; y = $p.Y; w = $r.R; h = $r.B }
}
function Captura($h, [string]$ficheiro) {
  $c = Cliente $h
  $bmp = New-Object System.Drawing.Bitmap $c.w, $c.h
  $g = [System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($c.x, $c.y, 0, 0, $bmp.Size); $g.Dispose()
  $bmp.Save($ficheiro, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
  return "$ficheiro $($c.w)x$($c.h)"
}
function CapturaAmbas([string]$ficheiro) {
  $cj = Cliente $J; $cm = Cliente $M
  $x0 = [math]::Min($cj.x, $cm.x); $y0 = [math]::Min($cj.y, $cm.y)
  $x1 = [math]::Max($cj.x + $cj.w, $cm.x + $cm.w); $y1 = [math]::Max($cj.y + $cj.h, $cm.y + $cm.h)
  $bmp = New-Object System.Drawing.Bitmap ($x1 - $x0), ($y1 - $y0)
  $g = [System.Drawing.Graphics]::FromImage($bmp); $g.Clear([System.Drawing.Color]::Black)
  $g.CopyFromScreen($cj.x, $cj.y, $cj.x - $x0, $cj.y - $y0, (New-Object System.Drawing.Size $cj.w, $cj.h))
  $g.CopyFromScreen($cm.x, $cm.y, $cm.x - $x0, $cm.y - $y0, (New-Object System.Drawing.Size $cm.w, $cm.h))
  $g.Dispose(); $bmp.Save($ficheiro, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
  return "$ficheiro"
}
$script:video = $null
function VideoInicio([string]$ficheiro, $h = $null, [int]$fps = 30) {
  if ($null -eq $h) { $cj = Cliente $J; $cm = Cliente $M
    $x0 = [math]::Min($cj.x, $cm.x); $y0 = [math]::Min($cj.y, $cm.y)
    $w = [math]::Max($cj.x + $cj.w, $cm.x + $cm.w) - $x0; $hh = [math]::Max($cj.y + $cj.h, $cm.y + $cm.h) - $y0 }
  else { $c = Cliente $h; $x0 = $c.x; $y0 = $c.y; $w = $c.w; $hh = $c.h }
  $w = $w - ($w % 2); $hh = $hh - ($hh % 2)
  $a = "-hide_banner -loglevel error -y -f gdigrab -framerate $fps -offset_x $x0 -offset_y $y0 -video_size ${w}x${hh} -draw_mouse 0 -i desktop -c:v libx264 -preset veryfast -crf 26 -pix_fmt yuv420p `"$ficheiro`""
  $psi = New-Object System.Diagnostics.ProcessStartInfo "$sede\tmp\ffmpeg.exe", $a
  $psi.UseShellExecute = $false; $psi.RedirectStandardInput = $true; $psi.CreateNoWindow = $true
  $script:video = [System.Diagnostics.Process]::Start($psi)
  return "video $ficheiro ${w}x${hh}@$x0,$y0"
}
function VideoFim() { if ($script:video) { $script:video.StandardInput.Write('q'); $script:video.WaitForExit(15000) | Out-Null; $script:video = $null; return 'video fechado' } }
function Ligar() {
  $pids = Get-Content "$sede\repo\bancada-rede\privado\pids.txt" | ? { $_ -match '^\d+$' }
  $gs = @($pids | % { Get-Process -Id ([int]$_) -ErrorAction SilentlyContinue } | ? { $_.ProcessName -like 'Godot*' })
  $script:J = JanelaDe $gs[0].Id; $script:M = JanelaDe $gs[$gs.Count - 1].Id
  return "J=$($script:J) (pid $($gs[0].Id)) $((Cliente $script:J) | ConvertTo-Json -Compress)  M=$($script:M) (pid $($gs[-1].Id)) $((Cliente $script:M) | ConvertTo-Json -Compress)"
}

"agente pronto sessao=$((Get-Process -Id $PID).SessionId) idle=$([U]::Idle())" | Out-File "$cmdDir\_agente.txt"
while (-not (Test-Path "$cmdDir\PARAR")) {
  $f = Get-ChildItem $cmdDir -Filter '*.ps1' | Sort-Object Name | Select-Object -First 1
  if ($null -eq $f) { Start-Sleep -Milliseconds 150; continue }
  $codigo = Get-Content $f.FullName -Raw
  Remove-Item $f.FullName -Force
  $out = try { . ([scriptblock]::Create($codigo)) 2>&1 | Out-String } catch { "ERRO: $_" }
  $out | Out-File -Encoding utf8 "$cmdDir\$($f.BaseName).out"
}
VideoFim | Out-Null
Remove-Item "$cmdDir\PARAR" -Force
