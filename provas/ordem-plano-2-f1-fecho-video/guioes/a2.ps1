Guarda
for ($k=0; $k -lt 5; $k++) { Mover $J (674+$k*2) (308+$k*2); Start-Sleep -Milliseconds 60 }
Start-Sleep -Milliseconds 300; Clicar $J 680 316 120; Start-Sleep -Milliseconds 1200
Captura $J "$CAP\b11-com-o-que2-jog.png"
