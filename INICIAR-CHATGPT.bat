@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title MCP PJe-TJCE v0.3.0 para ChatGPT

if not exist ".venv\Scripts\python.exe" (
  echo Primeira execucao detectada.
  echo Vou abrir a configuracao v0.3.0 antes de iniciar o MCP.
  echo.
  call "CONFIGURAR-V3.bat"
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
echo   MCP PJe-TJCE v0.3.0 - SERVIDOR LOCAL PARA CHATGPT
 echo ============================================================
echo.
echo Endpoint MCP local:
echo   http://%MCP_HOST%:%MCP_PORT%/mcp
echo Health:
echo   http://%MCP_HOST%:%MCP_PORT%/health
echo.
echo A autenticacao no PJe e concluida manualmente no navegador.
echo Nenhum seed TOTP e armazenado pelo projeto.
echo Mantenha esta janela aberta enquanto usar o plugin.
echo.
echo Para encerrar: feche esta janela ou pressione Ctrl+C.
echo ============================================================
echo.

".venv\Scripts\python.exe" "src\remote_server.py"

if errorlevel 1 (
  echo.
  echo [ERRO] O servidor MCP foi encerrado com erro.
  echo Execute DIAGNOSTICAR.bat para gerar um relatorio.
  pause
)

endlocal
