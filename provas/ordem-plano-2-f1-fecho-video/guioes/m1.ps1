Guarda
Clicar $J 580 683; Start-Sleep -Milliseconds 1200
Captura $J "$CAP\b01-mover1-alcance-jog.png"
Mover $J 597 352; Start-Sleep -Milliseconds 300; Clicar $J 597 352; Start-Sleep -Milliseconds 3000
Cap 'b02-depois-mov1'
for ($k=0; $k -lt 12; $k++) { Mover $J (1000+$k*4) (70+$k*3); Start-Sleep -Milliseconds 50 }
Start-Sleep -Milliseconds 500
Captura $J "$CAP\b03-caixa-expandida-jog.png"
for ($k=0; $k -lt 6; $k++) { Mover $J (640+$k*3) (560+$k*2); Start-Sleep -Milliseconds 50 }
Start-Sleep -Milliseconds 500
Captura $J "$CAP\b03c-caixa-compacta-jog.png"
