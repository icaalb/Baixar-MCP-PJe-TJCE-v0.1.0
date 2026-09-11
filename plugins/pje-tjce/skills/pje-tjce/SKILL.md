---
name: pje-tjce
description: Use este skill quando o usuário pedir consulta, leitura, movimentações, documentos ou preparação de análise de processo no PJe-TJCE. Priorize sempre operações de leitura e nunca pratique protocolo, assinatura, ciência, alteração, movimentação ou qualquer ato processual.
---

# PJe-TJCE

## Finalidade

Este skill orienta o uso do plugin PJe-TJCE para consulta processual assistida, com foco em atividades jurídicas de análise. O backend MCP é somente de leitura.

## Regras obrigatórias

1. Nunca inserir CPF, senha, segredo TOTP, cookie, token, certificado ou chave de sessão em prompts, logs, arquivos do repositório ou respostas ao usuário.
2. Nunca protocolar petições, assinar documentos, registrar ciência, alterar dados processuais ou praticar qualquer ato no PJe.
3. Quando houver dúvida sobre o grau, prefira o 2º grau apenas se o contexto indicar recurso, apelação, agravo, câmara, turma ou tribunal; caso contrário, peça ou use o grau explicitamente fornecido.
4. Trate resultados do PJe como dados processuais potencialmente sensíveis. Retorne apenas o necessário para a tarefa solicitada.
5. Se uma ferramenta falhar por mudança de interface ou seletor HTML, informe que o adaptador precisa ser ajustado e não tente contornar controles de segurança do PJe.
6. Não faça scraping massivo. Restrinja a consulta aos processos necessários ao trabalho do usuário.

## Fluxo recomendado

Quando o usuário fornecer um número CNJ e pedir análise:

1. Use `consultar_processo` para confirmar que o processo correto foi localizado.
2. Use `ultimas_movimentacoes` quando o pedido envolver andamento, fase processual ou decisão recente.
3. Use `listar_documentos` para identificar peças relevantes.
4. Use `ler_documento` somente em URLs retornadas pelo próprio backend PJe-TJCE.
5. Organize o resultado em sequência processual lógica, distinguindo dados extraídos dos autos de inferências analíticas.

## Exemplos de solicitações

- Consulte o processo 0000000-00.0000.8.06.0000 no 2º grau.
- Liste as últimas movimentações desse processo.
- Liste os documentos dos autos.
- Leia a decisão mais recente, se ela estiver disponível.

## Limites atuais

A versão inicial depende de automação Playwright e de seletores da interface web do PJe-TJCE. Mudanças no PJe podem exigir atualização do adaptador. Sempre prefira integração oficial do TJCE/CNJ quando houver endpoint institucional adequado.
