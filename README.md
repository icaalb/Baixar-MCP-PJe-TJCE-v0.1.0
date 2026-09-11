# MCP PJe-TJCE — v0.2.0

Servidor MCP experimental e **somente de leitura** para consulta ao Processo Judicial Eletrônico do Tribunal de Justiça do Estado do Ceará (PJe-TJCE), com suporte ao 1º e ao 2º graus.

A v0.2.0 acrescenta **Streamable HTTP** para conexão remota compatível com clientes MCP, inclusive cenários de integração com ChatGPT por endpoint remoto ou Secure MCP Tunnel.

## Estado desta versão

A autenticação foi projetada para o SSO nacional do PJe/PDPJ e os endpoints do TJCE estão configurados. Os identificadores observados no redirecionamento oficial são `pje-tjce-1g` e `pje-tjce-2g`.

Os seletores internos de consulta, perfil institucional, documentos e movimentações ainda precisam ser validados em uma sessão autenticada real do TJCE antes de uso institucional rotineiro.

## Princípios de segurança

- nenhuma senha, CPF, TOTP, cookie ou certificado é salvo no repositório;
- credenciais ficam no cofre de credenciais do sistema via `keyring`;
- cookies permanecem apenas na sessão de navegador;
- o servidor não possui ferramentas de protocolo, assinatura, ciência, movimentação ou alteração processual;
- URLs de documentos são aceitas apenas no domínio `pje.tjce.jus.br`;
- sessão é encerrada automaticamente após inatividade;
- o servidor remoto local usa `127.0.0.1` por padrão e não deve ser exposto diretamente à internet.

## Endpoints do PJe-TJCE

| Grau | URL |
|---|---|
| 1º grau | `https://pje.tjce.jus.br/pje1grau` |
| 2º grau | `https://pje.tjce.jus.br/pje2grau` |

## Ferramentas MCP

- `status_pje`
- `consultar_processo`
- `ultimas_movimentacoes`
- `listar_documentos`
- `ler_documento`
- `encerrar_sessao`

## Instalação no Windows

```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m playwright install chromium
.\.venv\Scripts\python.exe setup_credenciais.py
```

## Uso local por stdio

```powershell
$env:PJE_HEADLESS="0"
.\.venv\Scripts\python.exe src\server.py
```

Exemplo genérico de cliente MCP:

```json
{
  "mcpServers": {
    "pje-tjce": {
      "command": "C:\\CAMINHO\\mcp-pje-tjce\\.venv\\Scripts\\python.exe",
      "args": ["C:\\CAMINHO\\mcp-pje-tjce\\src\\server.py"]
    }
  }
}
```

## Uso remoto / ChatGPT

A v0.2.0 inclui `src/remote_server.py`, que publica o MCP por **Streamable HTTP**.

No Windows, basta executar:

```text
INICIAR-CHATGPT.bat
```

Ou:

```powershell
$env:PJE_HEADLESS="0"
$env:MCP_HOST="127.0.0.1"
$env:MCP_PORT="8000"
.\.venv\Scripts\python.exe src\remote_server.py
```

Endpoints locais:

```text
MCP:    http://127.0.0.1:8000/mcp
Health: http://127.0.0.1:8000/health
```

O ChatGPT não se conecta diretamente a MCP local. Para uso a partir de máquina local/rede privada, utilize o **Secure MCP Tunnel** indicado pela documentação oficial da OpenAI ou outro endpoint remoto protegido e aprovado.

Instruções detalhadas: [`docs/CHATGPT.md`](docs/CHATGPT.md).

## Perfil institucional MPCE

Não há seleção automática de perfil por padrão. Após validar o texto exato exibido pelo PJe para o perfil institucional, ele poderá ser definido por variável de ambiente:

```powershell
$env:PJE_TJCE_PROFILE_HINT="texto exato do perfil"
```

A seleção automática somente tentará clicar em elemento cujo texto contenha o valor configurado.

## Variáveis de ambiente

Consulte `.env.example`. Principais opções:

```text
PJE_HEADLESS=0
PJE_WARMUP=0
PJE_TJCE_PROFILE_HINT=
MCP_HOST=127.0.0.1
MCP_PORT=8000
MCP_JSON_RESPONSE=1
```

Nunca coloque credenciais do PJe em `.env`.

## Teste inicial recomendado

1. execute `setup_credenciais.py`;
2. use `PJE_HEADLESS=0`;
3. inicie `INICIAR-CHATGPT.bat` ou `src/remote_server.py`;
4. acesse `http://127.0.0.1:8000/health`;
5. conecte um cliente MCP ao endpoint `/mcp`;
6. chame `status_pje(grau="2g")`;
7. valide visualmente o perfil selecionado;
8. chame `consultar_processo` com um processo permitido ao usuário;
9. registre qualquer seletor/tela não reconhecido para ajuste do adaptador.

## Arquitetura

```text
ChatGPT / cliente MCP
        |
        | HTTPS / Secure MCP Tunnel
        v
Streamable HTTP /mcp
        |
        v
FastMCP
        |
        v
Playwright + sessão local
        |
        v
PJe-TJCE 1º/2º grau
```

## Origem arquitetural

Projeto escrito de forma independente. A arquitetura foi estudada a partir de implementações públicas de MCP para PJe, em especial o repositório `fxbarros/MCP-PJe-TJMA`, sem incorporar credenciais ou dados pessoais e sem presumir compatibilidade de seletores entre tribunais.

## Limitações

O PJe é uma aplicação web dinâmica e seus seletores podem variar por versão, perfil e tribunal. Scraping de interface não deve ser tratado como API estável. Para implantação institucional, deve-se preferir integração oficial quando TJCE/CNJ disponibilizar endpoint apropriado ao caso de uso.

A disponibilidade de apps MCP personalizados no ChatGPT depende do plano, das permissões administrativas e das regras atuais do produto OpenAI. Consulte sempre a documentação oficial antes da implantação.
