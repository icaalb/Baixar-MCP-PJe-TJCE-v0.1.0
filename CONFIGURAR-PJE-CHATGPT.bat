@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Configurar MCP PJe-TJCE para ChatGPT

set "PYTHON_CMD="
set "PYTHON_ARGS="

call :detectar_python
if errorlevel 1 goto :python_nao_encontrado

echo ============================================================
echo   MCP PJe-TJCE - CONFIGURACAO AUTOMATICA PARA WINDOWS
echo ============================================================
echo.
echo Este assistente prepara o servidor local MCP em modo somente leitura.
echo Ele NAO altera politicas do Windows e NAO instala o Secure MCP Tunnel.
echo A etapa do Tunel sera concluida na interface do ChatGPT.
echo.

echo [1/6] Python encontrado:
call :python_exec --version
if errorlevel 1 goto :erro

echo.
echo [2/6] Criando ambiente virtual...
if not exist ".venv\Scripts\python.exe" (
  call :python_exec -m venv .venv
  if errorlevel 1 goto :erro
) else (
  echo Ambiente virtual ja existe. Mantendo configuracao atual.
)

echo.
echo [3/6] Atualizando pip e instalando dependencias...
".venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 goto :erro
".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 goto :erro

echo.
echo [4/6] Instalando Chromium do Playwright...
".venv\Scripts\python.exe" -m playwright install chromium
if errorlevel 1 goto :erro

echo.
echo [5/6] Configurando credenciais do PJe/PDPJ...
echo Os dados serao gravados no cofre de credenciais do Windows.
echo Nao serao salvos no GitHub.
echo.
".venv\Scripts\python.exe" setup_credenciais.py
if errorlevel 1 goto :erro

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
echo IMPORTANTE: o ChatGPT nao acessa 127.0.0.1 diretamente.
echo O Secure MCP Tunnel deve ser configurado na propria interface compativel do ChatGPT.
echo.
pause
exit /b 0

:detectar_python
rem 1) Preferir o Python Launcher real, se instalado.
where py >nul 2>nul
if not errorlevel 1 (
  py -3 -c "import sys; print(sys.executable)" >nul 2>nul
  if not errorlevel 1 (
    set "PYTHON_CMD=py"
    set "PYTHON_ARGS=-3"
    exit /b 0
  )
)

rem 2) Tentar python.exe do PATH. O alias da Microsoft Store falha no teste -c.
where python >nul 2>nul
if not errorlevel 1 (
  python -c "import sys; print(sys.executable)" >nul 2>nul
  if not errorlevel 1 (
    set "PYTHON_CMD=python"
    set "PYTHON_ARGS="
    exit /b 0
  )
)

rem 3) Procurar instalacoes comuns do Python fora do PATH.
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
  if exist "%%~P" (
    "%%~P" -c "import sys; print(sys.executable)" >nul 2>nul
    if not errorlevel 1 (
      set "PYTHON_CMD=%%~P"
      set "PYTHON_ARGS="
      exit /b 0
    )
  )
)

exit /b 1

:python_exec
if /I "%PYTHON_CMD%"=="py" (
  py %PYTHON_ARGS% %*
) else (
  "%PYTHON_CMD%" %*
)
exit /b %errorlevel%

:python_nao_encontrado
cls
echo ============================================================
echo   PYTHON NAO ENCONTRADO
necho ============================================================
echo.
echo O Windows nao encontrou uma instalacao real do Python 3.10 ou superior.
echo O comando "python" pode estar apontando apenas para o atalho da Microsoft Store.
echo.
echo COMO CORRIGIR:
echo.
echo 1. Instale o Python 3.12 ou superior pelo instalador oficial.
echo    Durante a instalacao, marque: Add python.exe to PATH
echo.
echo 2. Se o Windows continuar abrindo a Microsoft Store, abra:
echo    Configuracoes ^> Aplicativos ^> Configuracoes avancadas de aplicativos
necho    ^> Aliases de execucao do aplicativo
necho.
echo 3. Desative os aliases:
echo       python.exe
necho       python3.exe
necho.
echo 4. Feche esta janela, abra outra e teste:
echo       py --version
necho    ou:
echo       python --version
necho.
echo 5. Quando aparecer "Python 3.10" ou superior, execute novamente:
echo       CONFIGURAR-PJE-CHATGPT.bat
necho.
echo O configurador nao altera essas configuracoes automaticamente por seguranca.
echo.
pause
exit /b 1

:erro
echo.
echo [ERRO] A configuracao foi interrompida.
echo Copie a mensagem exibida acima ou envie uma captura de tela para diagnostico.
pause
exit /b 1
