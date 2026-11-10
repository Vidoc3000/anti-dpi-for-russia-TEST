@echo off
start "" "%SystemRoot%\System32\conhost.exe" "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0AntiDPI_Manager.ps1" -Action Install
if errorlevel 1 pause
