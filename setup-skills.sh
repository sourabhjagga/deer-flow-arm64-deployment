#!/bin/sh
set -e

echo "Starting setup script..."

mkdir -p /app/backend/config
mkdir -p /app/backend/skills/public
mkdir -p /app/backend/skills/custom

# Generate config.yaml with all models
cat << 'CFG' > /app/backend/config.yaml
models:
  - name: 9router-google-fast
    display_name: Google Fast
    use: langchain_openai:ChatOpenAI
    model: google-fast
    api_key: ${NINE_ROUTER_API_KEY:-placeholder}
    base_url: ${NINE_ROUTER_BASE_URL:-http://9router:9000/v1}
    max_tokens: 8192
    supports_vision: true
  - name: 9router-google-pro
    display_name: Google Pro
    use: langchain_openai:ChatOpenAI
    model: google-pro
    api_key: ${NINE_ROUTER_API_KEY:-placeholder}
    base_url: ${NINE_ROUTER_BASE_URL:-http://9router:9000/v1}
    max_tokens: 8192
    supports_vision: true
  - name: 9router-claude
    display_name: Claude
    use: langchain_openai:ChatOpenAI
    model: claude
    api_key: ${NINE_ROUTER_API_KEY:-placeholder}
    base_url: ${NINE_ROUTER_BASE_URL:-http://9router:9000/v1}
    max_tokens: 8192
    supports_vision: true
  - name: 9router-deepseek
    display_name: Deepseek
    use: langchain_openai:ChatOpenAI
    model: deepseek
    api_key: ${NINE_ROUTER_API_KEY:-placeholder}
    base_url: ${NINE_ROUTER_BASE_URL:-http://9router:9000/v1}
    max_tokens: 8192
    supports_vision: true
  - name: 9router-qwen
    display_name: Qwen
    use: langchain_openai:ChatOpenAI
    model: qwen
    api_key: ${NINE_ROUTER_API_KEY:-placeholder}
    base_url: ${NINE_ROUTER_BASE_URL:-http://9router:9000/v1}
    max_tokens: 8192
    supports_vision: true
  - name: 9router-everything-else
    display_name: Everything Else
    use: langchain_openai:ChatOpenAI
    model: everything-else
    api_key: ${NINE_ROUTER_API_KEY:-placeholder}
    base_url: ${NINE_ROUTER_BASE_URL:-http://9router:9000/v1}
    max_tokens: 8192
    supports_vision: true
tool_groups:
  - name: web
  - name: file:read
  - name: file:write
  - name: bash
sandbox:
  use: deerflow.sandbox.local:LocalSandboxProvider
  allow_host_bash: true
tools:
  - name: web_search
    group: web
    use: deerflow.community.ddg_search.tools:web_search_tool
  - name: web_fetch
    group: web
    use: deerflow.community.jina_ai.tools:web_fetch_tool
  - name: image_search
    group: web
    use: deerflow.community.image_search.tools:image_search_tool
  - name: ls
    group: file:read
    use: deerflow.sandbox.tools:ls_tool
  - name: read_file
    group: file:read
    use: deerflow.sandbox.tools:read_file_tool
  - name: glob
    group: file:read
    use: deerflow.sandbox.tools:glob_tool
  - name: grep
    group: file:read
    use: deerflow.sandbox.tools:grep_tool
  - name: write_file
    group: file:write
    use: deerflow.sandbox.tools:write_file_tool
  - name: str_replace
    group: file:write
    use: deerflow.sandbox.tools:str_replace_tool
  - name: bash
    group: bash
    use: deerflow.sandbox.tools:bash_tool
memory:
  enabled: true
  storage_path: memory.json
checkpointer:
  type: sqlite
  connection_string: checkpoints.db
skills:
  path: /app/backend/skills
  container_path: /app/backend/skills
CFG

# We need to substitute variables since we used quotes in heredoc
sed -i "s|\${NINE_ROUTER_API_KEY:-placeholder}|${NINE_ROUTER_API_KEY:-placeholder}|g" /app/backend/config.yaml
sed -i "s|\${NINE_ROUTER_BASE_URL:-http://9router:9000/v1}|${NINE_ROUTER_BASE_URL:-http://9router:9000/v1}|g" /app/backend/config.yaml

echo "Config generated successfully."

# Download skills if not present
if [ ! -d "/app/backend/skills/public/deep-research" ]; then
  echo "Downloading built-in skills..."
  python3 -c "
import urllib.request, tarfile, io, os
try:
    req = urllib.request.Request('https://github.com/bytedance/deer-flow/archive/refs/heads/main.tar.gz', headers={'User-Agent': 'Mozilla/5.0'})
    response = urllib.request.urlopen(req)
    tar = tarfile.open(fileobj=io.BytesIO(response.read()), mode='r:gz')
    for m in tar.getmembers():
        if m.name.startswith('deer-flow-main/skills/public/'):
            m.name = m.name.replace('deer-flow-main/skills/public/', '', 1)
            if m.name:
                tar.extract(m, '/app/backend/skills/public')
    print('Skills downloaded successfully.')
except Exception as e:
    print('Failed to download skills:', e)
"
fi

# Enable skills in extensions_config.json
echo "Configuring extensions..."
python3 -c "
import os, json
d='/app/backend/skills/public'
s={f: {'enabled': True} for f in os.listdir(d) if os.path.isdir(os.path.join(d, f))} if os.path.exists(d) else {}
with open('/app/backend/extensions_config.json', 'w') as f:
    json.dump({'mcpServers': {}, 'skills': s}, f)
"

echo "Starting Gateway..."
cd /app/backend && PYTHONPATH=. uv run uvicorn app.gateway.app:app --host 0.0.0.0 --port 8001 --workers 1
