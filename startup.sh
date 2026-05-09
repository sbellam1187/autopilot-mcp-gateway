#!/bin/bash
set -e

echo "MCP Server Startup Script"
echo "========================="

# Read environment variables or set defaults
MCP_SERVER_TYPE=${MCP_SERVER_TYPE:-"everything"}
MCP_PORT=${MCP_PORT:-8081}
MCP_COMMAND_TYPE=${MCP_COMMAND_TYPE:-"npx"}  # npx, uvx, uv, python
MCP_PACKAGE=${MCP_PACKAGE:-"@modelcontextprotocol/server-everything"}
MCP_ARGS=${MCP_ARGS:-""}
USE_SUPERARGS=${USE_SUPERARGS:-false}

# Build the MCP server command based on type
SERVER_CMD=""
case "$MCP_COMMAND_TYPE" in
  "npx")
    SERVER_CMD="npx -y ${MCP_PACKAGE}"
    ;;
  "uvx")
    SERVER_CMD="uvx ${MCP_PACKAGE}"
    ;;
  "uv")
    SERVER_CMD="uv ${MCP_PACKAGE}"
    ;;
  "python3")
    SERVER_CMD="${MCP_PACKAGE}"
    ;;
  *)
    echo "Unknown command type: ${MCP_COMMAND_TYPE}"
    exit 1
    ;;
esac

# Launching MCP Server (Conditional based on USE_SUPERARGS):
echo "Launching MCP Server (Type: $MCP_SERVER_TYPE, Port: $MCP_PORT)"
if [ "$USE_SUPERARGS" = "true" ]; then
  echo "Superargs logic removed for simplicity."
else
  eval "${SERVER_CMD} ${MCP_ARGS}"
fi

# Launch Supergateway
echo "Launching Supergateway (Port: $MCP_PORT)"
npx -y supergateway \
    --stdio "$SERVER_CMD ${MCP_ARGS}" \
    --port "$MCP_PORT" --baseUrl http://localhost:"$MCP_PORT" \
    --outputTransport streamableHttp --streamableHttpPath /mcp --stateful --sessionTimeout 60000 --healthEndpoint /healthz