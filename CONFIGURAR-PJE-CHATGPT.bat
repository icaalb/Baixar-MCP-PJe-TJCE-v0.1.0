@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Configurar MCP PJe-TJCE para ChatGPT

set "PYTHON_CMD="
set "PYTHON_EXE="

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

if not defined PYTHON_CMD (
  for %%K in (
    "HKCU\Software\Python\PythonCore\3.13\InstallPath"
    "HKCU\Software\Python\PythonCore\3.12\InstallPath"
    "HKCU\Software\Python\PythonCore\3.11\InstallPath"
    "HKCU\Software\Python\PythonCore\3.10\InstallPath"
    "HKLM\Software\Python\PythonCore\3.13\InstallPath"
    "HKLM\Software\Python\PythonCore\3.12\InstallPath"
    "HKLM\Software\Python\PythonCore\3.11\InstallPath"
    "HKLM\Software\Python\PythonCore\3.10\InstallPath"
    "HKLM\Software\WOW6432Node\Python\PythonCore\3.13\InstallPath"
    "HKLM\Software\WOW6432Node\Python\PythonCore\3.12\InstallPath"
    "HKLM\Software\WOW6432Node\Python\PythonCore\3.11\InstallPath"
    "HKLM\Software\WOW6432Node\Python\PythonCore\3.10\InstallPath"
  ) do (
    if not defined PYTHON_CMD (
      for /f "tokens=2,*" %%A in ('reg query %%~K /ve 2^>nul ^| findstr /I "REG_SZ"') do (
        set "PYTHON_EXE=%%Bpython.exe"
        if exist "!PYTHON_EXE!" (
          "!PYTHON_EXE!" -c "import sys; print(sys.executable)" >nul 2>nul
          if not errorlevel 1 set "PYTHON_CMD="!PYTHON_EXE!""
        )
      )
    )
  )
)

if not defined PYTHON_CMD (
  cls
  echo ============================================================
  echo   PYTHON NAO LOCALIZADO
  echo ============================================================
  echo.
  echo O Windows nao encontrou um executavel funcional do Python 3.10 ou superior.
  echo.
  where winget >nul 2>nul
  if not errorlevel 1 (
    winget list --id Python.Python.3.12 -e >nul 2>nul
    if not errorlevel 1 (
      echo O winget informa que o Python 3.12 JA ESTA INSTALADO,
      echo mas o executavel nao foi localizado. Isso indica uma instalacao quebrada,
      echo PATH incorreto ou registro inconsistente.
      echo.
      choice /C SN /N /M "Deseja REPARAR reinstalando o Python 3.12 para o usuario atual? [S/N]: "
      if errorlevel 2 (
        echo.
        echo Reparo cancelado.
      ) else (
        echo.
        echo Removendo o registro/instalacao atual do Python 3.12...
        winget uninstall --id Python.Python.3.12 -e --scope user --silent
        echo.
        echo Instalando novamente o Python 3.12...
        winget install --id Python.Python.3.12 -e --scope user --accept-package-agreements --accept-source-agreements --silent
      )
    ) else (
      echo O Python 3.12 nao esta instalado pelo winget.
      echo.
      choice /C SN /N /M "Deseja instalar o Python 3.12 agora? [S/N]: "
      if errorlevel 2 (
        echo.
        echo Instalacao cancelada.
      ) else (
        winget install --id Python.Python.3.12 -e --scope user --accept-package-agreements --accept-source-agreements --silent
      )
    )

    if exist "%LocalAppData%\Programs\Python\Python312\python.exe" (
      "%LocalAppData%\Programs\Python\Python312\python.exe" -c "import sys; print(sys.executable)" >nul 2>nul
      if not errorlevel 1 set "PYTHON_CMD="%LocalAppData%\Programs\Python\Python312\python.exe""
    )
  ) else (
    echo O winget nao esta disponivel neste computador.
  )
)

if not defined PYTHON_CMD (
  echo.
  echo ============================================================
  echo   ACAO MANUAL NECESSARIA
  echo ============================================================
  echo.
  echo 1. Abra Configuracoes ^> Aplicativos ^> Configuracoes avancadas de aplicativos
  echo    ^> Aliases de execucao do aplicativo.
  echo.
  echo 2. Desative os aliases:
  echo       python.exe
  echo       python3.exe
  echo.
  echo 3. Feche TODAS as janelas do Terminal/Prompt e abra uma nova.
  echo.
  echo 4. Teste:
  echo       py --version
  echo    ou:
  echo       python --version
  echo.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo   MCP PJe-TJCE - CONFIGURACAO AUTOMATICA PARA WINDOWS
echo ============================================================
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

echo Corrigindo compatibilidade do SDK MCP...
".venv\Scripts\python.exe" -m pip install --upgrade --force-reinstall "mcp>=1.12.0,<2"
if errorlevel 1 (
  echo [ERRO] Falha ao instalar uma versao compativel do MCP SDK.
  pause
  exit /b 1
)

".venv\Scripts\python.exe" -m pip install --upgrade -r requirements.txt
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
