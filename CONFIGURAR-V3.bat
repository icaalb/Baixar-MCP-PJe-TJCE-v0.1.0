@echo off
setlocal
cd /d "%~dp0"
title Configurar MCP PJe-TJCE v0.3.0

echo ============================================================
echo   MCP PJe-TJCE v0.3.0 - CONFIGURACAO
 echo ============================================================
echo.

where py >nul 2>nul
if not errorlevel 1 (
  set "PY=py -3"
) else (
  where python >nul 2>nul
  if errorlevel 1 (
    echo [ERRO] Python 3.10 ou superior nao foi localizado.
    echo Instale o Python e execute este arquivo novamente.
    pause
    exit /b 1
  )
  set "PY=python"
)

%PY% --version
if errorlevel 1 (
  echo [ERRO] Python nao pode ser executado.
  pause
  exit /b 1
)

if not exist ".venv\Scripts\python.exe" (
  echo Criando ambiente virtual...
  %PY% -m venv .venv
  if errorlevel 1 exit /b 1
)

echo Atualizando dependencias...
".venv\Scripts\python.exe" -m pip install --upgrade pip
".venv\Scripts\python.exe" -m pip install --upgrade -r requirements.txt
if errorlevel 1 (
  echo [ERRO] Falha ao instalar as dependencias.
  pause
  exit /b 1
)

echo Instalando Chromium do Playwright...
".venv\Scripts\python.exe" -m playwright install chromium
if errorlevel 1 (
  echo [ERRO] Falha ao instalar Chromium.
  pause
  exit /b 1
)

echo.
".venv\Scripts\python.exe" setup_credenciais.py

echo.
echo Executando testes...
".venv\Scripts\python.exe" -m pytest -q

echo.
echo Configuracao v0.3.0 concluida.
echo A autenticacao no PJe sera feita manualmente no navegador.
echo.
pause
