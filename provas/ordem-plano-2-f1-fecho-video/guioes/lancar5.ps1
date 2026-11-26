$i=[U]::Idle(); if ($i -lt 300) { "PC OCUPADO idle=$i - nao lanco"; return }
$script:R='<JV>\ordem-plano-2-f1-fecho-video-pc'
$script:CAP="$R\tmp\cap4"
$a = "-NoProfile -ExecutionPolicy Bypass -File `"$R\repo\bancada-rede\lancar.ps1`" -Fichas acertam -Modo auto -Motor real -Porta 8791 -HostServidor 127.0.0.1 -SemEspera"
$p = Start-Process powershell -ArgumentList $a -PassThru -WindowStyle Minimized -RedirectStandardOutput "$R\tmp\lancar5.log" -RedirectStandardError "$R\tmp\lancar5.err"
$p.WaitForExit(240000) | Out-Null
"idle=$i lancador saiu=$($p.HasExited) hora=$(Get-Date -Format HH:mm:ss)"
Get-Content "$R\tmp\lancar5.log"
