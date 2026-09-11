from __future__ import annotations

from config import MCP_HOST, MCP_JSON_RESPONSE, MCP_PORT
from server import mcp


if __name__ == "__main__":
    # Para uso local/por túnel seguro, mantenha MCP_HOST=127.0.0.1.
    # Só altere o bind para interface externa em ambiente controlado.
    mcp.run(
        transport="streamable-http",
        host=MCP_HOST,
        port=MCP_PORT,
        json_response=MCP_JSON_RESPONSE,
    )
