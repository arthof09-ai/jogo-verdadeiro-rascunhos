Start-Sleep -Milliseconds 2000
Cap 'd01-fim'
Clicar $M 1470 16; Start-Sleep -Milliseconds 1200
Captura $M "$CAP\d02-mestre-registo-fim.png"
Clicar $M 1170 16; Start-Sleep -Milliseconds 1000
Captura $M "$CAP\d03-mestre-figuras-fim.png"
Start-Sleep 2
VideosFim
"idle=$([U]::Idle())"
