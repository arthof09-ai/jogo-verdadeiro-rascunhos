Guarda
Clicar $J 460 683; Start-Sleep -Milliseconds 1200
Captura $J "$CAP\b04-ataque-alvos-jog.png"
for ($k=0; $k -lt 5; $k++) { Mover $J (550+$k*2) (296+$k); Start-Sleep -Milliseconds 60 }
Start-Sleep -Milliseconds 300; Clicar $J 558 300 120; Start-Sleep -Milliseconds 1200
Captura $J "$CAP\b05-com-o-que-jog.png"
