#!/bin/bash

set -eu

echo "==> Setting up directories"
mkdir -p /app/data/generated

# Create env config file on first run
if [[ ! -f /app/data/env.sh ]]; then
    echo "==> Creating default configuration"
    cat > /app/data/env.sh << 'ENVEOF'
# API Tokens for external services
# Edit these values and restart the app

# GitHub token (for projects and starred repos)
# Create at: https://github.com/settings/tokens
export FORGE_TOKENS='{"github.com": ""}'

# GitHub username for starred repos
export GITHUB_USERNAME="rmdes"

# Bluesky credentials (optional, for feed)
export BLUESKY_IDENTIFIER=""
export BLUESKY_APP_PASSWORD=""

# Mastodon credentials (optional, for feed)
export MASTODON_ACCESS_TOKEN=""
export MASTODON_INSTANCE=""
ENVEOF
fi

# Load environment configuration
source /app/data/env.sh

echo "==> Generating projects data"
if [[ -n "${FORGE_TOKENS:-}" ]] && [[ "${FORGE_TOKENS}" != '{"github.com": ""}' ]]; then
    /app/pkg/ps-gen-projects -projects /app/code/data/projects.yaml 2>/dev/null > /app/data/generated/projects_gen.yaml || echo "Warning: Failed to generate projects"
else
    echo "Warning: FORGE_TOKENS not configured, skipping projects generation"
    echo "[]" > /app/data/generated/projects_gen.yaml
fi

echo "==> Generating starred repos data"
if [[ -n "${FORGE_TOKENS:-}" ]] && [[ "${FORGE_TOKENS}" != '{"github.com": ""}' ]]; then
    /app/pkg/ps-gen-starred -username "${GITHUB_USERNAME:-rmdes}" -limit 30 2>/dev/null > /app/data/generated/starred_gen.yaml || echo "Warning: Failed to generate starred repos"
else
    echo "Warning: FORGE_TOKENS not configured, skipping starred repos generation"
    echo "[]" > /app/data/generated/starred_gen.yaml
fi

# Create writable directories for Hugo resources/cache
mkdir -p /app/data/hugo/resources /app/data/hugo/cache

# Ensure proper ownership for data directory
chown -R cloudron:cloudron /app/data

echo "==> Starting application server"
cd /app/code
exec gosu cloudron:cloudron env \
    HUGO_RESOURCEDIR=/app/data/hugo/resources \
    HUGO_CACHEDIR=/app/data/hugo/cache \
    /app/pkg/ps-proxy \
    -laddr="0.0.0.0:8000" \
    -scmd='hugo server --baseURL=/ --appendPort=false --bind=127.0.0.1 --port=1313 --noBuildLock --renderToMemory' \
    -surl='http://127.0.0.1:1313/' \
    -acmd='/app/pkg/ps-api' \
    -aurl='http://127.0.0.1:1314/'
