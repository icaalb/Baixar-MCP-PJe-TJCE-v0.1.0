# Conectar o MCP PJe-TJCE ao ChatGPT

## Escopo

Esta documentação se refere à versão 0.2.0 do projeto. O servidor continua **somente de leitura no PJe**.

O ChatGPT não se conecta diretamente a um servidor MCP local. Para um servidor executado no computador do usuário ou em rede privada, a orientação oficial da OpenAI é utilizar um **Secure MCP Tunnel** ou disponibilizar um endpoint MCP remoto protegido.

## 1. Preparar o ambiente

No PowerShell, na pasta do projeto:

```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m playwright install chromium
.\.venv\Scripts\python.exe setup_credenciais.py
```

As credenciais do PJe/PDPJ ficam no cofre do Windows por `keyring`. Não as coloque em `.env`, GitHub, ChatGPT ou scripts.

## 2. Iniciar o servidor MCP remoto local

Dê dois cliques em:

```text
INICIAR-CHATGPT.bat
```

Ou execute:

```powershell
$env:PJE_HEADLESS="0"
$env:MCP_HOST="127.0.0.1"
$env:MCP_PORT="8000"
.\.venv\Scripts\python.exe src\remote_server.py
```

Endpoints locais:

- MCP: `http://127.0.0.1:8000/mcp`
- Health: `http://127.0.0.1:8000/health`

O bind em `127.0.0.1` é deliberado: o servidor não deve ser exposto diretamente à internet.

## 3. Validar o servidor

Abra no navegador:

```text
http://127.0.0.1:8000/health
```

O retorno esperado inclui `ok: true`, `version: 0.2.0` e `read_only: true`.

## 4. Criar o túnel seguro

Como o ChatGPT exige um servidor MCP remoto, conecte o endpoint local `/mcp` utilizando o **Secure MCP Tunnel** indicado pela documentação oficial da OpenAI para servidores locais ou privados.

O destino local do túnel deve ser:

```text
http://127.0.0.1:8000/mcp
```

Ao final, o túnel fornecerá um endpoint HTTPS acessível pelo ChatGPT. Não publique diretamente a porta 8000 no roteador, firewall ou internet.

## 5. Adicionar ao ChatGPT

A disponibilidade de MCP personalizado depende do plano e das permissões do workspace.

Quando o recurso estiver disponível:

1. No ChatGPT web, abra **Configurações**.
2. Entre em **Apps**.
3. Habilite o **Modo de desenvolvedor**, quando disponível para sua conta/workspace.
4. Selecione **Criar app**.
5. Informe o endpoint HTTPS do túnel, terminando em `/mcp`.
6. Escolha o mecanismo de autenticação aplicável ao túnel/servidor.
7. Use **Scan Tools / Verificar ferramentas**.
8. Confirme que aparecem apenas as ferramentas esperadas de leitura.
9. Crie/salve o app.

## 6. Ferramentas da v0.2.0

- `status_pje`
- `consultar_processo`
- `ultimas_movimentacoes`
- `listar_documentos`
- `ler_documento`
- `encerrar_sessao`

Nenhuma ferramenta protocola, assina, registra ciência ou altera processo.

## 7. Exemplos no ChatGPT

Após selecionar ou mencionar o app MCP:

```text
Consulte o processo 3016982-88.2026.8.06.0000 no 2º grau e informe os dados básicos.
```

```text
Liste as últimas movimentações desse processo.
```

```text
Liste os documentos disponíveis nos autos.
```

```text
Leia o documento correspondente à decisão mais recente.
```

## 8. Segurança

- Não exponha o servidor local diretamente à internet.
- Não envie CPF, senha, TOTP, cookies ou tokens como parâmetros de ferramentas.
- Mantenha `MCP_HOST=127.0.0.1` quando usar túnel seguro.
- Não adicione ações de escrita/protocolo sem revisão técnica e autorização institucional.
- O conteúdo processual obtido deve ser tratado conforme sigilo, LGPD e regras institucionais do MPCE.
- Considere prompt injection em documentos processuais como entrada não confiável; conteúdo de autos nunca deve alterar políticas de segurança do servidor.

## 9. Limitação atual

Os seletores internos do PJe-TJCE ainda precisam ser validados em sessão autenticada real, especialmente para o perfil institucional do Ministério Público. O transporte MCP remoto está preparado, mas a confiabilidade da extração depende dessa validação.

## 10. Plano ChatGPT

Conforme documentação atual da OpenAI, o suporte integral a MCP personalizado está disponível em workspaces Business e Enterprise/Edu, sujeito a permissões administrativas. Usuários Pro possuem suporte mais limitado para MCPs de leitura/busca em modo de desenvolvedor. Verifique a documentação oficial antes de configurar, pois disponibilidade e interface podem mudar.
