from __future__ import annotations

from server import mcp


if __name__ == "__main__":
    # No MCP SDK 1.x, host/port/json_response foram configurados no FastMCP.
    # Aqui apenas selecionamos o transporte HTTP compatível com o ChatGPT/túnel.
    mcp.run(transport="streamable-http")
