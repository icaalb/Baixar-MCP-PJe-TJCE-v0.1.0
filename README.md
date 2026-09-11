# MCP PJe-TJCE — v0.1.0

Servidor MCP experimental e **somente de leitura** para consulta ao Processo Judicial Eletrônico do Tribunal de Justiça do Estado do Ceará (PJe-TJCE), com suporte ao 1º e ao 2º graus.

## Estado desta versão

A autenticação foi projetada para o SSO nacional do PJe/PDPJ e os endpoints do TJCE estão configurados. Os identificadores observados no redirecionamento oficial são `pje-tjce-1g` e `pje-tjce-2g`.

A v0.1.0 deve ser considerada **adaptador inicial**: os seletores internos de consulta, perfil institucional, documentos e movimentações precisam ser validados em uma sessão autenticada real do TJCE antes de uso institucional rotineiro.

## Princípios de segurança

- nenhuma senha, CPF, TOTP, cookie ou certificado é salvo no repositório;
- credenciais ficam no cofre de credenciais do sistema via `keyring`;
- cookies permanecem apenas na sessão de navegador;
- o servidor não possui ferramentas de protocolo, assinatura, ciência, movimentação ou alteração processual;
- URLs de documentos são aceitas apenas no domínio `pje.tjce.jus.br`;
- sessão é encerrada automaticamente após inatividade.

## Endpoints

| Grau | URL |
|---|---|
| 1º grau | `https://pje.tjce.jus.br/pje1grau` |
| 2º grau | `https://pje.tjce.jus.br/pje2grau` |

## Ferramentas MCP iniciais

- `status_pje`
- `consultar_processo`
- `ultimas_movimentacoes`
- `listar_documentos`
- `ler_documento`
- `encerrar_sessao`

## Instalação no Windows

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
playwright install chromium
python setup_credenciais.py
```

Para depuração visual:

```powershell
$env:PJE_HEADLESS="0"
python src\server.py
```

Por segurança, `PJE_WARMUP` vem desligado. Para ativar login antecipado ao iniciar o MCP:

```powershell
$env:PJE_WARMUP="1"
```

## Configuração em cliente MCP

Exemplo genérico de configuração por `stdio`:

```json
{
  "mcpServers": {
    "pje-tjce": {
      "command": "C:\\CAMINHO\\mcp-pje-tjce\\.venv\\Scripts\\python.exe",
      "args": ["C:\\CAMINHO\\mcp-pje-tjce\\src\\server.py"],
      "env": {
        "PJE_HEADLESS": "0",
        "PJE_WARMUP": "0"
      }
    }
  }
}
```

## Perfil institucional MPCE

Não há seleção automática de perfil por padrão. Após validar o texto exato exibido pelo PJe para o perfil institucional, ele poderá ser definido por variável de ambiente:

```powershell
$env:PJE_TJCE_PROFILE_HINT="texto exato do perfil"
```

A seleção automática somente tentará clicar em elemento cujo texto contenha o valor configurado.

## Teste inicial recomendado

1. executar `python setup_credenciais.py`;
2. definir `PJE_HEADLESS=0`;
3. iniciar `python src/server.py` por um cliente MCP;
4. chamar `status_pje(grau="2g")`;
5. validar visualmente o perfil selecionado;
6. chamar `consultar_processo` com um processo permitido ao usuário;
7. registrar qualquer seletor/tela que não seja reconhecido para ajuste do adaptador.

## Origem arquitetural

Projeto escrito de forma independente. A arquitetura foi estudada a partir de implementações públicas de MCP para PJe, em especial o repositório `fxbarros/MCP-PJe-TJMA`, sem incorporar credenciais ou dados pessoais e sem presumir compatibilidade de seletores entre tribunais.

## Limitações

O PJe é uma aplicação web dinâmica e seus seletores podem variar por versão, perfil e tribunal. Não se deve tratar scraping de interface como API estável. Para implantação institucional, deve-se preferir integração oficial quando o TJCE/CNJ disponibilizar endpoint apropriado ao caso de uso.
