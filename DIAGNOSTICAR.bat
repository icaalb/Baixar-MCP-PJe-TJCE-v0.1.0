@echo off
setlocal
cd /d "%~dp0"
title Diagnostico MCP PJe-TJCE

set "LOG=diagnostico-pje-tjce.txt"
(
  echo MCP PJe-TJCE - DIAGNOSTICO
  echo Data: %date% %time%
  echo Pasta: %cd%
  echo.
  echo === Windows ===
  ver
  echo.
  echo === Python ===
  if exist ".venv\Scripts\python.exe" (
    ".venv\Scripts\python.exe" --version
    echo.
    echo === MCP SDK ===
    ".venv\Scripts\python.exe" -c "import mcp, importlib.metadata as md; print(md.version('mcp'))"
    echo.
    echo === Playwright ===
    ".venv\Scripts\python.exe" -c "import playwright; print('playwright import OK')"
    echo.
    echo === Imports do projeto ===
    ".venv\Scripts\python.exe" -c "import sys; sys.path.insert(0,'src'); import config, pje_client_v3, cliente_singleton_v3, server; print('imports OK', config.VERSION)"
  ) else (
    echo Ambiente virtual .venv nao encontrado.
  )
  echo.
  echo === Porta 8000 ===
  netstat -ano | findstr ":8000"
  echo.
  echo === Health local ===
  curl.exe -s --max-time 3 http://127.0.0.1:8000/health
  echo.
  echo.
  echo === Fim ===
) > "%LOG%" 2>&1

type "%LOG%"
echo.
echo Relatorio salvo em: %cd%\%LOG%
pause
