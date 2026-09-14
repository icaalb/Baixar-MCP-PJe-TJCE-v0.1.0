from __future__ import annotations

from config import MCP_HOST, MCP_JSON_RESPONSE, MCP_MAX_REQUEST_BODY, MCP_PORT
from server import mcp


if __name__ == "__main__":
    mcp.run(
        transport="streamable-http",
        host=MCP_HOST,
        port=MCP_PORT,
        json_response=MCP_JSON_RESPONSE,
        max_request_body_size=MCP_MAX_REQUEST_BODY,
    )
