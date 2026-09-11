from __future__ import annotations

import os

from server import mcp


def _env_bool(name: str, default: bool) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "sim", "on"}


if __name__ == "__main__":
    host = os.environ.get("MCP_HOST", "127.0.0.1")
    port = int(os.environ.get("MCP_PORT", "8000"))
    json_response = _env_bool("MCP_JSON_RESPONSE", True)

    # Para uso local/por túnel seguro, mantenha 127.0.0.1.
    # Só altere o bind para interface externa em ambiente controlado.
    mcp.run(
        transport="streamable-http",
        host=host,
        port=port,
        json_response=json_response,
    )
