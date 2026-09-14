from __future__ import annotations

import asyncio
from contextlib import asynccontextmanager
from datetime import datetime, timezone

from mcp.server import MCPServer
from starlette.responses import JSONResponse

import cliente_singleton_v3 as cliente_singleton
from config import MCP_NAME, TRIBUNAL, VERSION, WARMUP, normalize_grau


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


mcp = MCPServer(MCP_NAME, lifespan=lifespan)


def _meta(payload: dict, grau: str) -> dict:
    payload["tribunal"] = TRIBUNAL
    payload["grau"] = "2º grau" if normalize_grau(grau) == "2g" else "1º grau"
    payload["somente_leitura"] = True
    payload["versao"] = VERSION
    payload["mcp_sdk"] = "2.x"
    return payload


@mcp.custom_route("/health", methods=["GET"])
async def health_http(_request):
    return JSONResponse(
        {
            "ok": True,
            "service": MCP_NAME,
            "tribunal": TRIBUNAL,
            "version": VERSION,
            "read_only": True,
            "mcp_sdk": "2.x",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
    )


@mcp.tool()
async def status_pje(grau: str = "2g") -> dict:
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.health(), grau)


@mcp.tool()
async def consultar_processo(numero_cnj: str, grau: str = "2g") -> dict:
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.consultar_processo(numero_cnj), grau)


@mcp.tool()
async def ultimas_movimentacoes(numero_cnj: str, limite: int = 10, grau: str = "2g") -> dict:
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.ultimas_movimentacoes(numero_cnj, limite), grau)


@mcp.tool()
async def listar_documentos(numero_cnj: str, grau: str = "2g") -> dict:
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.listar_documentos(numero_cnj), grau)


@mcp.tool()
async def preparar_processo_para_analise(numero_cnj: str, grau: str = "2g") -> dict:
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.preparar_processo_para_analise(numero_cnj), grau)


@mcp.tool()
async def ler_documento(url: str, grau: str = "2g") -> dict:
    client = await cliente_singleton.get_client(grau)
    return _meta(await client.ler_url_documento(url), grau)


@mcp.tool()
async def encerrar_sessao() -> dict:
    await cliente_singleton.close_client()
    return {"ok": True, "tribunal": TRIBUNAL, "versao": VERSION}


if __name__ == "__main__":
    mcp.run()
