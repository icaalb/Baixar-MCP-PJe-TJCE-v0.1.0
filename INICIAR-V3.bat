@echo off
setlocal
cd /d "%~dp0"
title MCP PJe-TJCE v0.3.0

if not exist ".venv\Scripts\python.exe" (
  echo Ambiente virtual nao encontrado.
  echo Execute CONFIGURAR-V3.bat primeiro.
  pause
  exit /b 1
)

if "%PJE_HEADLESS%"=="" set PJE_HEADLESS=0
if "%MCP_HOST%"=="" set MCP_HOST=127.0.0.1
if "%MCP_PORT%"=="" set MCP_PORT=8000
if "%MCP_JSON_RESPONSE%"=="" set MCP_JSON_RESPONSE=1

echo ============================================================
echo   MCP PJe-TJCE v0.3.0 - SERVIDOR LOCAL
 echo ============================================================
echo.
echo Endpoint MCP: http://%MCP_HOST%:%MCP_PORT%/mcp
echo Health:       http://%MCP_HOST%:%MCP_PORT%/health
echo.
echo O navegador sera aberto quando a primeira ferramenta acessar o PJe.
echo Conclua o login e o segundo fator manualmente no navegador.
echo Mantenha esta janela aberta enquanto usar o plugin.
echo.

".venv\Scripts\python.exe" "src\remote_server.py"

if errorlevel 1 (
  echo.
  echo [ERRO] O servidor MCP foi encerrado com erro.
  echo Execute DIAGNOSTICAR.bat e envie o resultado para analise.
  pause
)
