@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Configurar MCP PJe-TJCE para ChatGPT

echo ============================================================
echo   MCP PJe-TJCE - CONFIGURACAO AUTOMATICA PARA WINDOWS
echo ============================================================
echo.
echo Este assistente prepara o servidor local MCP em modo somente leitura.
echo Ele NAO altera politicas do Windows e NAO instala o Secure MCP Tunnel.
echo A etapa do Tunel sera concluida na interface do ChatGPT.
echo.

where py >nul 2>nul
if errorlevel 1 (
  where python >nul 2>nul
  if errorlevel 1 (
    echo [ERRO] Python nao encontrado.
    echo Instale Python 3.10 ou superior, ou solicite a instalacao a TI.
    pause
    exit /b 1
  )
  set PYTHON=python
) else (
  set PYTHON=py
)

echo [1/6] Verificando Python...
%PYTHON% --version
if errorlevel 1 goto :erro

echo.
echo [2/6] Criando ambiente virtual...
if not exist ".venv\Scripts\python.exe" (
  %PYTHON% -m venv .venv
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
echo O Secure MCP Tunnel deve ser configurado na propria interface compatível do ChatGPT.
echo.
pause
exit /b 0

:erro
echo.
echo [ERRO] A configuracao foi interrompida.
echo Copie a mensagem exibida acima ou envie uma captura de tela para diagnostico.
pause
exit /b 1
