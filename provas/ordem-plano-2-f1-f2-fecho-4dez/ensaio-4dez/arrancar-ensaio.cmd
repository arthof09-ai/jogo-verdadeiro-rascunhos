@echo off
rem ORDEM-PLANO-2-F1-F2-FECHO-4DEZ (B3): a mesa do ensaio da casa num duplo clique. Opcoes: -Web ^<pasta^> -Porta 8080
title Mesa do ensaio 4/12
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0arrancar-ensaio.ps1" %*
if errorlevel 1 pause
