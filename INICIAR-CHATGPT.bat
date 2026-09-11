@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title MCP PJe-TJCE para ChatGPT

if not exist ".venv\Scripts\python.exe" (
  echo Primeira execucao detectada.
  echo Vou abrir a configuracao automatica antes de iniciar o MCP.
  echo.
  call "CONFIGURAR-PJE-CHATGPT.bat"
  if errorlevel 1 (
    echo.
    echo [ERRO] A configuracao nao foi concluida.
    pause
    exit /b 1
  )
)

if "%PJE_HEADLESS%"=="" set PJE_HEADLESS=0
if "%PJE_WARMUP%"=="" set PJE_WARMUP=0
if "%MCP_HOST%"=="" set MCP_HOST=127.0.0.1
if "%MCP_PORT%"=="" set MCP_PORT=8000
if "%MCP_JSON_RESPONSE%"=="" set MCP_JSON_RESPONSE=1

echo ============================================================
echo   MCP PJe-TJCE - SERVIDOR LOCAL PARA CHATGPT
echo ============================================================
echo.
echo Endpoint MCP local:
echo   http://%MCP_HOST%:%MCP_PORT%/mcp
echo.
echo Mantenha esta janela aberta enquanto usar o plugin.
echo No ChatGPT, use a opcao TUNEL para conectar este servidor local.
echo.
echo Para encerrar: feche esta janela ou pressione Ctrl+C.
echo ============================================================
echo.

".venv\Scripts\python.exe" "src\remote_server.py"

if errorlevel 1 (
  echo.
  echo [ERRO] O servidor MCP foi encerrado com erro.
  echo Envie uma captura desta tela para diagnostico.
  pause
)

endlocal
