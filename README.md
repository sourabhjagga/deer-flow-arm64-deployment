# DeerFlow ARM64 Deployment for Oracle VM

Complete DeerFlow deployment configuration for Oracle ARM64 VM using Coolify, with LocalSandboxProvider (host access) for direct application building.

## Features Enabled

✅ All DeerFlow capabilities:
- 17 built-in skills (research, data analysis, code generation, presentations, etc.)
- Web search (DuckDuckGo - free, no API key)
- Web fetch and image search
- File operations (read, write, search)
- Bash command execution (on host via LocalSandboxProvider)
- Long-term memory (survives restarts)
- Subagents (parallel task execution)

✅ 9router LLM Gateway Integration
✅ Persistent data storage (survives container restarts)
✅ Cloudflare tunnel support
✅ ARM64 native Docker images

## Prerequisites

- Oracle VM with Docker + Docker Compose installed
- Coolify configured and connected to GitHub
- 9router credentials (API key + base URL)
- DockerHub images built: `sourabhjagga/deer-flow-backend:latest` and `sourabhjagga/deer-flow-frontend:latest`
- Cloudflare tunnel configured on Oracle VM

## Quick Setup

### 1. Clone this repository
```bash
git clone https://github.com/sourabhjagga/deer-flow-arm64-deployment.git
cd deer-flow-arm64-deployment
```

### 2. Create .env file
```bash
cp .env.example .env
```

Edit `.env` with your credentials:
```bash
NINE_ROUTER_API_KEY=your-actual-9router-key
BETTER_AUTH_SECRET=$(openssl rand -base64 32)
```

### 3. Create extensions_config.json
```bash
echo '{"mcpServers":{},"skills":{}}' > extensions_config.json
```

### 4. Create skills directory
```bash
mkdir -p skills
```

## Coolify Integration

### Option A: Manual Docker Compose (not using Coolify)
```bash
docker-compose up -d
```

Access at: `http://localhost:2026`

### Option B: Via Coolify (Recommended)

1. **In Coolify Dashboard:**
   - Click "New Project"
   - Connect to GitHub account
   - Select this repository (`sourabhjagga/deer-flow-arm64-deployment`)

2. **Configure Deployment:**
   - Deployment type: Docker Compose
   - Compose file path: `docker-compose.yaml`
   - Auto-deploy: OFF (manual only)

3. **Add Environment Variables in Coolify:**
   - NINE_ROUTER_API_KEY
   - BETTER_AUTH_SECRET
   - NINE_ROUTER_BASE_URL
   - NINE_ROUTER_MODEL

4. **Deploy:**
   - Click "Deploy" button in Coolify UI
   - Wait for services to start (~2 minutes)
   - Click "View Logs" to monitor

## Accessing DeerFlow

### Local Access
```
http://localhost:2026
```

### Remote Access (via Cloudflare Tunnel)
```
https://your-subdomain.example.com
```

Your Cloudflare tunnel should route to `http://localhost:2026` on the Oracle VM.

## Agent Capabilities

### Can Do (Enabled)
✅ Build applications on Oracle VM filesystem
✅ Run shell commands directly on host
✅ Read/write code files
✅ Commit to GitHub via git commands
✅ Search the web
✅ Analyze data and create visualizations
✅ Generate documentation
✅ Build in parallel with subagents

### Cannot Do (Security)
❌ Escape the agent's configured scope
❌ Access files outside its working directory (unless /host mounted)
❌ Run without logging

## Updating Images

When new ARM64 images are built:

1. Trigger build in `sourabhjagga/deer-flow-arm64-builder`:
   - Go to GitHub Actions
   - Click "Run workflow"
   - Wait ~25 minutes

2. Update deployment:
   - Images auto-pull from DockerHub (if tagged `latest`)
   - In Coolify, click "Deploy" again
   - Or run: `docker-compose up -d --pull always`

## Configuration

### Edit DeerFlow Config
Edit `config.yaml` to change:
- LLM model settings
- Tool configurations
- Memory settings
- Skills enable/disable

Changes take effect on next deployment.

### Edit Nginx Config
Edit `nginx.conf` to change:
- Port mappings
- Reverse proxy settings
- Headers

Requires nginx container restart.

## Monitoring

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f gateway
docker-compose logs -f frontend
docker-compose logs -f nginx
```

### Health Checks
```bash
# Gateway health
curl http://localhost:8001/health

# Models list
curl http://localhost:2026/api/models

# Frontend
curl http://localhost:3000
```

## Security Notes

⚠️ **LocalSandboxProvider Warning:**
- Agent has direct access to Oracle VM filesystem
- Agent can run bash commands on host
- Agent is trusted - only use with models you trust
- No isolation boundary between agent and host

For production, consider:
- Restricting agent bash access (set `allow_host_bash: false`)
- Using AioSandboxProvider (Docker sandbox) instead
- Running behind authentication
- Monitoring agent actions via logs

## Troubleshooting

### Gateway won't start
```bash
# Check if port 8001 is free
netstat -tlnp | grep 8001

# Check logs
docker-compose logs gateway

# Rebuild and restart
docker-compose down
docker-compose up -d
```

### Frontend blank page
- Check browser console for errors
- Verify BETTER_AUTH_SECRET is set
- Check nginx logs: `docker-compose logs nginx`
- Verify frontend container is running: `docker ps`

### Agent can't execute bash
- Verify `allow_host_bash: true` in config.yaml
- Check Docker socket is mounted: `ls -la /var/run/docker.sock`
- Check gateway logs for permission errors
- Restart gateway container

### 9router connection failed
- Verify 9router is running and reachable
- Check NINE_ROUTER_BASE_URL in .env
- Check NINE_ROUTER_API_KEY is correct
- Test connection: `curl http://localhost:9000/health`
- Look at gateway logs for connection errors

### Data not persisting after restart
- Verify `deer-flow-data` volume exists: `docker volume ls`
- Check volume mount in docker-compose.yaml
- Verify .deer-flow directory has write permissions

## File Structure

```
deer-flow-arm64-deployment/
├── docker-compose.yaml     # Services orchestration (Coolify compatible)
├── config.yaml             # DeerFlow configuration
├── nginx.conf              # Reverse proxy config
├── .env.example            # Environment variables template
├── .env                    # Actual credentials (git-ignored)
├── extensions_config.json  # MCP servers & skills state
├── skills/                 # Custom skills directory (optional)
└── README.md               # This file
```

## Next Steps

1. ✅ Build ARM64 images (via GitHub Actions in separate repo)
2. ✅ Deploy via Coolify (follow guide above)
3. 📝 Add 9router service in separate deployment
4. 📝 Configure additional MCP servers
5. 📝 Set up monitoring and alerting
6. 📝 Create custom skills for your use case

## Resources

- **DeerFlow Official Docs:** https://deerflow.tech/en/docs
- **DeerFlow GitHub:** https://github.com/bytedance/deer-flow
- **Coolify Docs:** https://coolify.io/docs
- **Docker Compose Reference:** https://docs.docker.com/compose/

## Support

For DeerFlow-specific issues:
- GitHub Issues: https://github.com/bytedance/deer-flow/issues
- Official Docs: https://deerflow.tech/en/docs

For deployment issues:
- Check troubleshooting section above
- Review Coolify logs
- Verify Oracle VM resources (CPU, RAM, disk)

---

Built with ❤️ for Oracle ARM64 VM deployment
