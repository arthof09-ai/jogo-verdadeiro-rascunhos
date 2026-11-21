@echo off
rem ORDEM-CORR10-PREP: fecha o servidor e os clientes da bancada de rede (os pids de privado\pids.txt).
if not exist "%~dp0privado\pids.txt" (echo Nada a parar. & exit /b 0)
for /f "usebackq" %%p in ("%~dp0privado\pids.txt") do taskkill /PID %%p /F >nul 2>&1
del "%~dp0privado\pids.txt"
echo Bancada parada.
