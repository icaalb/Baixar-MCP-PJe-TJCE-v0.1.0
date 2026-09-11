@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Configurar MCP PJe-TJCE para ChatGPT

set "PYTHON_CMD="

rem ============================================================
rem Detectar Python real
rem ============================================================

where py >nul 2>nul
if not errorlevel 1 (
  py -3 -c "import sys; print(sys.executable)" >nul 2>nul
  if not errorlevel 1 set "PYTHON_CMD=py -3"
)

if not defined PYTHON_CMD (
  where python >nul 2>nul
  if not errorlevel 1 (
    python -c "import sys; print(sys.executable)" >nul 2>nul
    if not errorlevel 1 set "PYTHON_CMD=python"
  )
)

if not defined PYTHON_CMD (
  for %%P in (
    "%LocalAppData%\Programs\Python\Python313\python.exe"
    "%LocalAppData%\Programs\Python\Python312\python.exe"
    "%LocalAppData%\Programs\Python\Python311\python.exe"
    "%LocalAppData%\Programs\Python\Python310\python.exe"
    "%ProgramFiles%\Python313\python.exe"
    "%ProgramFiles%\Python312\python.exe"
    "%ProgramFiles%\Python311\python.exe"
    "%ProgramFiles%\Python310\python.exe"
  ) do (
    if not defined PYTHON_CMD if exist "%%~P" (
      "%%~P" -c "import sys; print(sys.executable)" >nul 2>nul
      if not errorlevel 1 set "PYTHON_CMD="%%~P""
    )
  )
)

rem ============================================================
rem Se Python nao existir, oferecer instalacao automatica via winget
rem ============================================================

if not defined PYTHON_CMD (
  cls
  echo ============================================================
  echo   PYTHON NAO ENCONTRADO
  echo ============================================================
  echo.
  echo O Windows nao encontrou uma instalacao real do Python 3.10 ou superior.
  echo.
  where winget >nul 2>nul
  if not errorlevel 1 (
    echo O Windows Package Manager ^(winget^) esta disponivel.
    echo Posso instalar o Python 3.12 somente para o usuario atual.
    echo Essa instalacao nao altera politicas institucionais do Windows.
    echo.
    choice /C SN /N /M "Deseja instalar o Python 3.12 agora? [S/N]: "
    if errorlevel 2 (
      echo.
      echo Instalacao cancelada pelo usuario.
    ) else (
      echo.
      echo Instalando Python 3.12...
      winget install --id Python.Python.3.12 -e --scope user --accept-package-agreements --accept-source-agreements
      if not errorlevel 1 (
        if exist "%LocalAppData%\Programs\Python\Python312\python.exe" (
          set "PYTHON_CMD="%LocalAppData%\Programs\Python\Python312\python.exe""
        )
      )
    )
  ) else (
    echo O winget nao esta disponivel neste computador.
  )
)

if not defined PYTHON_CMD (
  echo.
  echo ============================================================
  echo   INSTALACAO MANUAL NECESSARIA
  echo ============================================================
  echo.
  echo 1. Instale o Python 3.12 ou superior pelo instalador oficial.
  echo    Durante a instalacao, marque: Add python.exe to PATH
  echo.
  echo 2. Se o Windows continuar abrindo a Microsoft Store, abra:
  echo    Configuracoes ^> Aplicativos ^> Configuracoes avancadas de aplicativos
  echo    ^> Aliases de execucao do aplicativo
  echo.
  echo 3. Desative os aliases:
  echo       python.exe
  echo       python3.exe
  echo.
  echo 4. Depois abra uma nova janela e teste:
  echo       py --version
  echo    ou:
  echo       python --version
  echo.
  echo 5. Quando aparecer Python 3.10 ou superior, execute novamente:
  echo       CONFIGURAR-PJE-CHATGPT.bat
  echo.
  pause
  exit /b 1
)

rem ============================================================
rem Configuracao do MCP
rem ============================================================

echo.
echo ============================================================
echo   MCP PJe-TJCE - CONFIGURACAO AUTOMATICA PARA WINDOWS
echo ============================================================
echo.
echo Este assistente prepara o servidor local MCP em modo somente leitura.
echo Ele NAO altera politicas do Windows e NAO instala o Secure MCP Tunnel.
echo.

echo [1/6] Python encontrado:
%PYTHON_CMD% --version
if errorlevel 1 (
  echo [ERRO] Nao foi possivel executar o Python detectado.
  pause
  exit /b 1
)

echo.
echo [2/6] Criando ambiente virtual...
if not exist ".venv\Scripts\python.exe" (
  %PYTHON_CMD% -m venv .venv
  if errorlevel 1 (
    echo [ERRO] Falha ao criar o ambiente virtual.
    pause
    exit /b 1
  )
) else (
  echo Ambiente virtual ja existe. Mantendo configuracao atual.
)

echo.
echo [3/6] Atualizando pip e instalando dependencias...
".venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 (
  echo [ERRO] Falha ao atualizar o pip.
  pause
  exit /b 1
)
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 (
  echo [ERRO] Falha ao instalar as dependencias.
  pause
  exit /b 1
)

echo.
echo [4/6] Instalando Chromium do Playwright...
".venv\Scripts\python.exe" -m playwright install chromium
if errorlevel 1 (
  echo [ERRO] Falha ao instalar o Chromium do Playwright.
  pause
  exit /b 1
)

echo.
echo [5/6] Configurando credenciais do PJe/PDPJ...
echo Os dados serao gravados no cofre de credenciais do Windows.
echo Nao serao salvos no GitHub.
echo.
".venv\Scripts\python.exe" setup_credenciais.py
if errorlevel 1 (
  echo [ERRO] Falha ao configurar as credenciais.
  pause
  exit /b 1
)

echo.
echo [6/6] Executando testes basicos...
".venv\Scripts\python.exe" -m pytest -q
if errorlevel 1 (
  echo [AVISO] Os testes nao terminaram com sucesso.
  echo A configuracao principal foi concluida, mas revise a mensagem acima.
) else (
  echo Testes basicos concluidos com sucesso.
)

echo.
echo ============================================================
echo   CONFIGURACAO LOCAL CONCLUIDA
echo ============================================================
echo.
echo Proximo passo:
echo   1. De dois cliques em INICIAR-CHATGPT.bat
echo   2. Mantenha a janela aberta
echo   3. No ChatGPT, em Novo plugin, selecione a aba TUNEL
echo   4. Aponte o tunel para: http://127.0.0.1:8000/mcp
echo   5. Depois crie o plugin PJe-TJCE
echo.
pause
exit /b 0
