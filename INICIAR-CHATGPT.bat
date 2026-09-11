@echo off
setlocal
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
  echo [ERRO] Ambiente virtual nao encontrado.
  echo Execute primeiro: py -m venv .venv
  echo Depois: .venv\Scripts\python.exe -m pip install -r requirements.txt
  pause
  exit /b 1
)

if "%PJE_HEADLESS%"=="" set PJE_HEADLESS=0
if "%PJE_WARMUP%"=="" set PJE_WARMUP=0
if "%MCP_HOST%"=="" set MCP_HOST=127.0.0.1
if "%MCP_PORT%"=="" set MCP_PORT=8000
if "%MCP_JSON_RESPONSE%"=="" set MCP_JSON_RESPONSE=1

echo MCP PJe-TJCE v0.2.0
echo Endpoint local: http://%MCP_HOST%:%MCP_PORT%/mcp
echo Health check:  http://%MCP_HOST%:%MCP_PORT%/health
echo.

".venv\Scripts\python.exe" "src\remote_server.py"

endlocal
