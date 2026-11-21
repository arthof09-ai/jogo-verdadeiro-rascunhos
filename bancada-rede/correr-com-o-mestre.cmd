@echo off
rem ORDEM-CORR10-PREP: a bancada de rede verdadeira num duplo clique (servidor do jogo + clientes Godot ja na sala).
rem Opcoes (passam ao lancar.ps1): -Aliada  -SoLobby  -Motor auto^|real^|falso  -Modo manual^|semi^|auto  -Porta 8790  -Godot ^<exe^>
title Bancada de rede - servidor do jogo
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lancar.ps1" %*
if errorlevel 1 pause
