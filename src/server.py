from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager

from mcp.server.fastmcp import FastMCP

import cliente_singleton
from config import MCP_NAME, TRIBUNAL, WARMUP, normalize_grau


async def _watchdog() -> None:
    while True:
        await asyncio.sleep(60)
        try:
            await cliente_singleton.close_if_idle()
        except Exception:
            pass


@asynccontextmanager
async def lifespan(_server):
    tasks = [asyncio.create_task(_watchdog())]
    if WARMUP:
        tasks.append(asyncio.create_task(cliente_singleton.get_client("2g")))
    try:
        yield {}
    finally:
        for task in tasks:
            task.cancel()
        await cliente_singleton.close_client()


mcp = FastMCP(MCP_NAME, lifespan=lifespan)


def _meta(payload: dict, grau: str) -> dict:
    payload["tribunal"] = TRIBUNAL
    payload["grau"] = "2º grau" if normalize_grau(grau) == "2g" else "1º grau"
    payload["somente_leitura"] = True
    return payload


@mcp.tool()
async def status_pje(grau: str = "2g") -> dict:
    """Verifica sessão autenticada e conectividade com o PJe-TJCE."""
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.health(), grau)


@mcp.tool()
async def consultar_processo(numero_cnj: str, grau: str = "2g") -> dict:
    """Consulta um processo no PJe-TJCE pelo número CNJ. Somente leitura."""
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.consultar_processo(numero_cnj), grau)


@mcp.tool()
async def ultimas_movimentacoes(numero_cnj: str, limite: int = 10, grau: str = "2g") -> dict:
    """Obtém movimentações candidatas do processo, sem praticar qualquer ato."""
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.ultimas_movimentacoes(numero_cnj, limite), grau)


@mcp.tool()
async def listar_documentos(numero_cnj: str, grau: str = "2g") -> dict:
    """Lista links candidatos a documentos/autos encontrados no processo."""
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.listar_documentos(numero_cnj), grau)


@mcp.tool()
async def ler_documento(url: str, grau: str = "2g") -> dict:
    """Extrai texto de um documento do domínio pje.tjce.jus.br previamente localizado."""
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.ler_url_documento(url), grau)


@mcp.tool()
async def encerrar_sessao() -> dict:
    """Encerra imediatamente a sessão local do navegador usada pelo MCP."""
    await cliente_singleton.close_client()
    return {"ok": True, "tribunal": TRIBUNAL}


if __name__ == "__main__":
    mcp.run()
