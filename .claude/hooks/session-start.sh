#!/bin/bash
set -euo pipefail

# Only run in remote Claude Code environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

CLOUDFLARED_BIN="/usr/local/bin/cloudflared"

# Install cloudflared if not present
if [ ! -f "$CLOUDFLARED_BIN" ]; then
  echo "Instalando cloudflared..."
  curl -sL --cacert /root/.ccr/ca-bundle.crt \
    "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64" \
    -o "$CLOUDFLARED_BIN"
  chmod +x "$CLOUDFLARED_BIN"
fi

# Start Python HTTP server on port 8080 if not already running
if ! lsof -i :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
  echo "Iniciando servidor HTTP en puerto 8080..."
  nohup python3 -m http.server 8080 \
    --directory "$(dirname "$0")/../.." \
    > /tmp/playbox-server.log 2>&1 &
  sleep 2
fi

# Start cloudflared tunnel and print the public URL
echo "Iniciando devtunnel (cloudflared)..."
nohup "$CLOUDFLARED_BIN" tunnel --url http://localhost:8080 \
  --no-autoupdate \
  > /tmp/cloudflared.log 2>&1 &

# Wait for the tunnel URL to appear in the log
for i in $(seq 1 30); do
  URL=$(grep -oP 'https://[a-z0-9\-]+\.trycloudflare\.com' /tmp/cloudflared.log 2>/dev/null | head -1)
  if [ -n "$URL" ]; then
    echo ""
    echo "========================================="
    echo "  PLAYBOX disponible en:"
    echo "  ${URL}/PLAYBOX.html"
    echo "========================================="
    # Persist URL to session env file if available
    if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
      echo "export PLAYBOX_URL=${URL}/PLAYBOX.html" >> "$CLAUDE_ENV_FILE"
    fi
    break
  fi
  sleep 1
done
