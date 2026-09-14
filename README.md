# MCP PJe-TJCE — v0.3.0

Servidor MCP experimental e **somente de leitura** para consulta ao Processo Judicial Eletrônico do Tribunal de Justiça do Estado do Ceará, com suporte ao 1º e ao 2º graus.

A v0.3.0 reorganiza a base para uso mais seguro e previsível no fluxo de análise jurídica: migração para **MCP SDK 2.x**, autenticação **manual no navegador** sem armazenamento de seed TOTP, nova ferramenta `preparar_processo_para_analise`, diagnóstico automático e testes adicionais.

## Mudanças principais da v0.3.0

- MCP SDK 2.x (`MCPServer`);
- Streamable HTTP em `/mcp`;
- nenhuma chave TOTP é solicitada ou armazenada;
- login/2FA são concluídos manualmente na janela do navegador;
- novo adaptador `src/pje_client_v3.py`;
- novo gerenciador de sessão `src/cliente_singleton_v3.py`;
- nova ferramenta `preparar_processo_para_analise`;
- `DIAGNOSTICAR.bat` gera relatório local de ambiente;
- `CONFIGURAR-V3.bat` e `INICIAR-V3.bat` simplificam a instalação e inicialização;
- limite de corpo de requisição MCP configurável;
- testes básicos adicionais em `tests/test_v3.py`.

## Segurança

O projeto permanece **somente leitura**. Não possui ferramentas de protocolo, assinatura, ciência, movimentação ou alteração processual.

A v0.3.0 não precisa armazenar CPF, senha nem seed TOTP para automatizar o segundo fator. Quando o PJe solicitar autenticação, o navegador é aberto e o usuário conclui o acesso manualmente. Cookies permanecem apenas na sessão local do navegador.

O servidor escuta em `127.0.0.1` por padrão. Não exponha a porta diretamente à internet.

## Endpoints TJCE

| Grau | URL |
|---|---|
| 1º grau | `https://pje.tjce.jus.br/pje1grau` |
| 2º grau | `https://pje.tjce.jus.br/pje2grau` |

## Ferramentas MCP

- `status_pje`
- `consultar_processo`
- `ultimas_movimentacoes`
- `listar_documentos`
- `preparar_processo_para_analise`
- `ler_documento`
- `encerrar_sessao`

### `preparar_processo_para_analise`

Essa ferramenta reúne, de forma preliminar, movimentações e links de documentos e tenta classificá-los em categorias úteis à análise jurídica, como decisão, sentença, acórdão, recurso, contrarrazões e manifestação do Ministério Público.

A classificação é heurística e deve ser conferida antes de uso em relatório ou parecer.

## Instalação recomendada no Windows

Baixe/extrai o repositório em uma pasta nova e execute:

```text
CONFIGURAR-V3.bat
```

Depois:

```text
INICIAR-CHATGPT.bat
```

ou:

```text
INICIAR-V3.bat
```

O servidor local ficará disponível em:

```text
MCP:    http://127.0.0.1:8000/mcp
Health: http://127.0.0.1:8000/health
```

Quando uma ferramenta precisar abrir o PJe, o Chromium será exibido. Conclua manualmente o login e o segundo fator e mantenha a janela aberta durante a sessão.

## Conexão ao ChatGPT

Para uso com plugin/app MCP do ChatGPT, conecte um túnel seguro ao endpoint local:

```text
http://127.0.0.1:8000/mcp
```

Não use `127.0.0.1` como URL remota diretamente no ChatGPT.

## Diagnóstico

Em caso de erro, execute:

```text
DIAGNOSTICAR.bat
```

Ele gera `diagnostico-pje-tjce.txt` com informações de Python, MCP SDK, Playwright, imports do projeto, porta 8000 e health check local. O relatório não deve conter credenciais.

## Variáveis de ambiente

```text
PJE_HEADLESS=0
PJE_WARMUP=0
PJE_TJCE_PROFILE_HINT=
PJE_IDLE_TIMEOUT=600
PJE_MANUAL_TOTP_TIMEOUT=180
MCP_HOST=127.0.0.1
MCP_PORT=8000
MCP_JSON_RESPONSE=1
MCP_MAX_REQUEST_BODY=2097152
```

## Estrutura atual

```text
src/
├── config.py
├── pje_client_v3.py
├── cliente_singleton_v3.py
├── server.py
└── remote_server.py

tests/
├── test_config.py
└── test_v3.py
```

Os arquivos `pje_client.py`, `cliente_singleton.py` e `security.py` pertencem à geração anterior e permanecem apenas como referência de transição. A execução principal da v0.3.0 utiliza os módulos `*_v3`.

## Limitações atuais

O PJe é uma aplicação web dinâmica. Os seletores internos ainda precisam ser validados com uma sessão autenticada real do TJCE. A ferramenta `preparar_processo_para_analise` é uma camada inicial de classificação e não substitui conferência documental.

A próxima evolução recomendada é observar as chamadas internas da própria interface PJe e, quando tecnicamente e institucionalmente permitido, substituir scraping visual por endpoints autenticados mais estáveis.

## Uso institucional

Antes de implantação rotineira, valide o comportamento com perfil autorizado do MPCE, revise as regras internas de segurança e proteção de dados e mantenha o projeto em modo somente leitura.
