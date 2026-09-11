# Plugin PJe-TJCE

Plugin local no formato atual do ecossistema OpenAI/Codex para consulta assistida ao PJe do Tribunal de Justiça do Estado do Ceará.

## Componentes

- `.codex-plugin/plugin.json`: manifesto do plugin.
- `.mcp.json`: conexão com o servidor MCP PJe-TJCE.
- `skills/pje-tjce/SKILL.md`: instruções de uso, segurança e fluxo jurídico.

## Pré-requisito

O backend MCP precisa estar em execução. No Windows, a partir da raiz do repositório:

```bat
INICIAR-CHATGPT.bat
```

Por padrão, o plugin local aponta para:

```text
http://127.0.0.1:8000/mcp
```

## Instalação local no Codex

A entrada de marketplace deste repositório está em:

```text
.agents/plugins/marketplace.json
```

O plugin está localizado em:

```text
plugins/pje-tjce
```

Instale ou carregue o marketplace/repositório conforme os controles disponíveis no Codex da sua conta. O plugin poderá ser invocado como `@PJe-TJCE` quando estiver instalado e habilitado.

## Uso com ChatGPT

O ChatGPT não acessa diretamente `127.0.0.1`. Para uso no ChatGPT, o mesmo servidor MCP deve ser disponibilizado por endpoint remoto compatível, preferencialmente por Secure MCP Tunnel ou infraestrutura institucional aprovada. Ao criar/importar o app no ChatGPT, use o endpoint remoto terminado em `/mcp`.

Exemplos:

```text
@PJe-TJCE consulte o processo 0000000-00.0000.8.06.0000 no 2º grau.
@PJe-TJCE liste as últimas movimentações do processo.
@PJe-TJCE liste os documentos disponíveis nos autos.
```

## Segurança

O plugin é somente de leitura. Não protocola, não assina, não registra ciência e não pratica atos processuais. Credenciais do PJe permanecem no cofre do sistema operacional utilizado pelo backend.
