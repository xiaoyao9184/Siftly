#!/bin/bash
set -e

# ── Siftly Launcher ───────────────────────────────────────────────────────────
# Run this once to set up and start Siftly.
# After first run, just run it again to start the app.
# ─────────────────────────────────────────────────────────────────────────────

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}  Siftly${NC}"
echo "  AI-powered bookmark manager"
echo ""

# ── 1. Create .env if missing ────────────────────────────────────────────────
if [ ! -f ".env" ]; then
  echo '  Creating .env with default DATABASE_URL...'
  echo 'DATABASE_URL="file:./prisma/dev.db"' > .env
  echo ""
fi

# ── 2. Install dependencies if needed ─────────────────────────────────────────
if [ ! -d "node_modules" ]; then
  echo "  Installing dependencies..."
  npm install
  echo ""
fi

# ── 3. Set up database if needed ──────────────────────────────────────────────
if [ ! -f "prisma/dev.db" ]; then
  echo "  Setting up database..."
  npx prisma generate
  npx prisma migrate deploy 2>/dev/null || npx prisma db push
  echo ""
fi

# ── 4. Check auth ─────────────────────────────────────────────────────────────
if command -v claude &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Claude CLI detected — AI features will use your subscription automatically"
else
  echo -e "  ${YELLOW}i${NC} Claude CLI not found. Add your API key in Settings after opening the app."
fi
echo ""

# ── 5. Start Cloudflare tunnel if token is present ───────────────────────────
PORT=${PORT:-3100}

# Source tunnel token from .env
if grep -q "CLOUDFLARE_TUNNEL_TOKEN" .env 2>/dev/null; then
  CLOUDFLARE_TUNNEL_TOKEN=$(grep "^CLOUDFLARE_TUNNEL_TOKEN=" .env | cut -d= -f2-)
fi

if [[ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]]; then
  echo -e "  ${GREEN}✓${NC} Cloudflare tunnel starting in background"
  cloudflared tunnel --no-autoupdate run --token "$CLOUDFLARE_TUNNEL_TOKEN" &
  TUNNEL_PID=$!
  trap "kill $TUNNEL_PID 2>/dev/null" EXIT
fi

# ── 6. Start the app ────────────────────────────────────────────────────────
echo "  Starting on http://localhost:$PORT"
echo "  Press Ctrl+C to stop"
echo ""

# Open browser after a short delay (cross-platform)
(sleep 2 && (xdg-open http://localhost:$PORT 2>/dev/null || open http://localhost:$PORT 2>/dev/null)) &

npx next dev -p $PORT
