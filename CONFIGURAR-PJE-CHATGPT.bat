@echo off
setlocal
cd /d "%~dp0"
title Configurar MCP PJe-TJCE v0.3.0

echo Este atalho agora usa o configurador v0.3.0.
echo.
call "CONFIGURAR-V3.bat"
exit /b %errorlevel%
