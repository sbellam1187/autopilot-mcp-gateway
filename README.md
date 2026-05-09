# Autopilot MCP Gateway & MCP Servers

A comprehensive Model Context Protocol (MCP) gateway and orchestration platform that provides centralized access to multiple MCP servers and AI services. This system acts as a unified entry point for various MCP servers, enabling seamless integration with AI agents and applications.

## 🏗️ Architecture

The Autopilot MCP Gateway consists of two main components:

### 1. **Nexus Gateway** (`autopilot-mcp-gateway`)
- **Base Image**: `docker.aa.com/prod/grafbase/nexus:latest`
- **Purpose**: Central gateway that routes MCP requests to appropriate servers
- **Configuration**: Uses `conf/nexus.toml` for routing and caching
- **Features**:
  - Health checks and monitoring
  - OAuth authentication support
  - Request caching for performance
  - Structured content support
  - Multiple transport protocols (SSE, HTTP, WebSocket)
  - Fuzzy search to find best tools avoiding exposing all tools at once

### 2. **MCP Wrapper** (`autopilot-mcp-wrapper`)
- **Base Image**: `docker.aa.com/prod/aa.com/node:23-dev`
- **Purpose**: Universal wrapper for Node.js/NPM-based MCP servers
- **Features**:
  - Utilizies Supergateway to run any MCP stdio over SSE/http_streamable
  - https://github.com/supercorp-ai/supergateway
  - Dynamic MCP server startup via `startup.sh`
  - Support for `npx`, `uvx`, `uv`, and `python` command types
  - Health check endpoints
  - Environment-based configuration

## 🧩 Supported MCP Servers

The platform integrates with the following MCP servers:

| Server | Port | Type | Description |
|--------|------|------|-------------|
| **aa-graph-mcp-server** | 8001 | Custom | AA Enterprise Graph operations |
| **caas-mcp-server** | 8002 | Custom | Container-as-a-Service operations |
| **fetch-mcp** | 8081 | NPM | Web fetching and HTTP operations |
| **sequential-thinking-mcp** | 8082 | NPM | Sequential reasoning capabilities |
| **azure-mcp** | 8083 | NPM | Azure cloud operations |
| **playwright-mcp** | 8084 | NPM | Web automation and testing |
| **slack-mcp** | 8085 | NPM | Slack integration |
| **azure-aks-mcp** | 8087 | Custom | Azure Kubernetes Service operations |
| **nexus** | 8006 | Gateway | Main MCP gateway service |

## 🚀 Quick Start & Local Development

### Prerequisites
- Docker and Docker Compose
- Environment variables configured (see [Configuration](#configuration))
- Authorization tokens configured (see [Authentication and Environment Configurations](#authentication-and-environment-configurations))

### 1. Clone and Setup
```bash
git clone https://github.com/AAInternal/autopilot-mcp-gateway.git
cd autopilot-mcp-gateway
cp example.env .env
# Edit .env with your configuration and update variables that require Auth tokens
# ex: AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, GITHUB_TOKEN, SLACK_MCP_XOXC_TOKEN, SLACK_MCP_XOXD_TOKEN
```

### 2. Build Images
```bash
# Build the MCP wrapper image
docker build -f Dockerfile-mcp-wrapper -t autopilot-mcp-wrapper .

# Build the gateway image  
docker build -f Dockerfile -t autopilot-mcp-gateway .
```

### 4. Start Services
```bash
docker-compose up -d
```

### 5. Use VSCode as MCP Client
- Copy PING SSO token from developer.aa.com
- Add the following to your mcp.json in VSCode by opening Command Pallate and searching for `MCP: Open Use Configuration`:
```json
{
	"servers": {
		"nexus": {
			"type": "http",
			"url": "http://localhost:3002/mcp",
			"headers": {
		 		"Authorization": "Bearer ${input:ping_sso_token}"
			}
		}
	},
	"inputs": [
		{
			"type": "promptString",
			"id": "ping_sso_token",
			"description": "PingFed SSO Token",
			"password": true
		}
	]
}
```
- Click on `start` above the word `nexus` and it will prompt for the token, paste the PING SSO token and hit enter
- Open GitHub Copilot Chat window in VSCode and set it to `Agent` mode and ask away

## ⚙️ Configuration

### Environment Variables

The system supports multiple configuration options via `.env` file:

#### MCP Server URLs
```bash
GRAPH_MCP_SERVER_URL=http://localhost:8002/mcp
GITHUB_MCP_SERVER_URL=http://localhost:8080/sse
AZURE_MCP_SERVER_URL=http://localhost:5008/sse
CAAS_MCP_SERVER_URL=http://localhost:8003/mcp
```

### Gateway Configuration

The Nexus gateway is configured via `conf/nexus.toml`:

```toml
[server]
listen_address = "0.0.0.0:8000"

[server.health]
enabled = true
path = "/health"

[mcp]
enabled = true
path = "/mcp"
enable_structured_content = true

[mcp.downstream_cache]
max_size = 1000
idle_timeout = "10m"
```

## 🐳 Docker Images

### autopilot-mcp-gateway
- **Purpose**: Main gateway service
- **Base**: Grafbase Nexus
- **Configuration**: Mounts `nexus.toml`

### autopilot-mcp-wrapper  
- **Purpose**: Universal MCP server wrapper
- **Base**: Node.js 23 development image
- **Startup**: Uses `startup.sh` for dynamic server initialization

## 🔧 Development

### Local Development
```bash
# Start individual services for debugging
docker-compose up aa-graph-mcp-server
docker-compose up caas-mcp-server
docker-compose up fetch-mcp

# View logs
docker-compose logs -f nexus
docker-compose logs -f fetch-mcp
```

### Adding New MCP Servers

1. **For NPM-based servers**, add to `docker-compose.yml`:
```yaml
your-mcp-server:
  image: localhost/autopilot-mcp-wrapper:latest
  container_name: your-mcp-server
  ports:
    - "8090:8090"
  environment:
    - MCP_SERVER_TYPE=your-mcp-server
    - MCP_PORT=8090
    - MCP_COMMAND_TYPE=npx
    - MCP_PACKAGE=your-package-name
  healthcheck:
    test: ["CMD", "wget", "--spider", "http://localhost:8090/healthz"]
    interval: 30s
    timeout: 10s
    retries: 5
```

2. **For custom servers**, add as separate service:
```yaml
your-custom-server:
  image: your-custom-mcp-server:latest
  container_name: your-custom-server
  ports:
    - "8090:8000"
  env_file:
    - .env
```

### Testing
```bash
# Test MCP server connectivity
curl -X POST http://localhost:8006/mcp \
  -H "Content-Type: application/json" \
  -d '{"method": "tools/list", "params": {}}'

# Test individual server health
curl http://localhost:8081/healthz
```

## 🔐 Security

- OAuth authentication support via PingFederate
- Environment-based secrets management
- Health check endpoints for monitoring
- Isolated container networking

## 📊 Monitoring & Observability

- Health check endpoints on all services
- Structured logging support
- Cache metrics available via Nexus
- Docker Compose health checks

## 🚀 CI/CD

The project includes automated CI/CD pipelines:

- **Workflow**: `.github/workflows/ci-taxiway.yaml`
- **Features**:
  - Automatic Docker image building
  - Security scanning with Aqua
  - Pull request validation
  - Dynamic app naming based on changed Dockerfiles

### Build Triggers
- `Dockerfile` changes → builds `autopilot-mcp-gateway`
- `Dockerfile-mcp-wrapper` changes → builds `autopilot-mcp-wrapper`
- Configuration changes in `conf/` directory

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📋 Troubleshooting

### Authentication and Environment Configurations

#### Slack Authentication Setup

Open up your Slack in your browser and login.

##### Lookup `SLACK_MCP_XOXC_TOKEN`

- Open your browser's Developer Console.
- In Firefox, under `Tools -> Browser Tools -> Web Developer tools` in the menu bar
- In Chrome, click the "three dots" button to the right of the URL Bar, then select
  `More Tools -> Developer Tools`
- Switch to the console tab.
- Type "allow pasting" and press ENTER.
- Paste the following snippet and press ENTER to execute:
  `JSON.parse(localStorage.localConfig_v2).teams[document.location.pathname.match(/^\/client\/([A-Z0-9]+)/)[1]].token`

Token value is printed right after the executed command (it starts with
`xoxc-`), save it somewhere for now.

##### Lookup `SLACK_MCP_XOXD_TOKEN`

- Switch to "Application" tab and select "Cookies" in the left navigation pane.
- Find the cookie with the name `d`.  That's right, just the letter `d`.
- Double-click the Value of this cookie.
- Press Ctrl+C or Cmd+C to copy it's value to clipboard.
- Save it for later.

##### Alternative: Using `SLACK_MCP_XOXP_TOKEN` (User OAuth)

Instead of using browser-based tokens (`xoxc`/`xoxd`), you can use a User OAuth token:

1. Go to [api.slack.com/apps](https://api.slack.com/apps) and create a new app
2. Under "OAuth & Permissions", add the following scopes:
    - `channels:history` - View messages in public channels
    - `channels:read` - View basic information about public channels
    - `groups:history` - View messages in private channels
    - `groups:read` - View basic information about private channels
    - `im:history` - View messages in direct messages.
    - `im:read` - View basic information about direct messages
    - `im:write` - Start direct messages with people on a user’s behalf (new since `v1.1.18`)
    - `mpim:history` - View messages in group direct messages
    - `mpim:read` - View basic information about group direct messages
    - `mpim:write` - Start group direct messages with people on a user’s behalf (new since `v1.1.18`)
    - `users:read` - View people in a workspace.
    - `chat:write` - Send messages on a user’s behalf. (new since `v1.1.18`)
    - `search:read` - Search a workspace’s content. (new since `v1.1.18`)

3. Install the app to your workspace
4. Copy the "User OAuth Token" (starts with `xoxp-`)

> **Note**: You only need **either** XOXP token **or** both XOXC/XOXD tokens. XOXP user tokens are more secure and don't require browser session extraction.

### Common Issues

**Port Conflicts**
```bash
# Check port usage
netstat -tulpn | grep :8081
# Stop conflicting services
docker-compose down
```

**MCP Server Not Starting**
```bash
# Check logs
docker-compose logs your-mcp-server
# Verify environment variables
docker-compose exec your-mcp-server env
```

**Gateway Connection Issues**
```bash
# Test direct MCP server access
curl http://localhost:8081/healthz
# Check nexus configuration
docker-compose exec nexus cat /etc/nexus.toml
```

## 📚 References

- [Model Context Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Grafbase Nexus Documentation](https://grafbase.com/docs)
- [MCP Server Examples](https://github.com/modelcontextprotocol/servers)

## License
Distributed under the MIT License. See LICENSE for more info.
