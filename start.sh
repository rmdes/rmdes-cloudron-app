#!/bin/bash

set -eu

echo "==> Setting up directories"

# Copy site to writable location on first run
if [[ ! -d /app/data/site ]]; then
    echo "==> First run: copying site to /app/data/site"
    cp -r /app/code /app/data/site
fi

# Always sync latest code (preserves generated data files)
echo "==> Syncing code updates"
rsync -a --exclude='data/projects_gen.yaml' --exclude='data/starred_gen.yaml' /app/code/ /app/data/site/

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

# Number of GitHub activities to show in carousel (1-10, default: 5)
export GITHUB_ACTIVITY_LIMIT="5"

# YouTube Data API v3 key (for channel/stream status)
# Create at: https://console.cloud.google.com/apis/credentials
export YOUTUBE_TOKEN=""

# Bluesky credentials (optional, for feed)
export BLUESKY_IDENTIFIER=""
export BLUESKY_APP_PASSWORD=""

# Mastodon credentials (optional, for feed)
export MASTODON_ACCESS_TOKEN=""
export MASTODON_INSTANCE=""
ENVEOF
fi

# Load environment configuration
# Support both .env (dotenv format) and env.sh (shell format)
if [[ -f /app/data/.env ]]; then
    echo "==> Loading /app/data/.env"
    set -a  # automatically export all variables
    source /app/data/.env
    set +a
elif [[ -f /app/data/env.sh ]]; then
    echo "==> Loading /app/data/env.sh"
    source /app/data/env.sh
fi

# Debug: show what binaries exist
echo "==> Checking binaries in /app/pkg/"
ls -la /app/pkg/

# Debug: verify binaries are executable
echo "==> Testing ps-gen-projects binary"
/app/pkg/ps-gen-projects -h 2>&1 | head -3 || echo "ERROR: ps-gen-projects failed to run"

echo "==> Generating projects data"
if [[ -n "${FORGE_TOKENS:-}" ]] && [[ "${FORGE_TOKENS}" != '{"github.com": ""}' ]]; then
    if /app/pkg/ps-gen-projects -forges /app/data/site/data/forges.yaml -projects /app/data/site/data/projects.yaml > /app/data/site/data/projects_gen.yaml; then
        echo "    Projects generated successfully"
    else
        echo "Warning: Failed to generate projects"
        echo "[]" > /app/data/site/data/projects_gen.yaml
    fi
else
    echo "Warning: FORGE_TOKENS not configured, skipping projects generation"
    echo "[]" > /app/data/site/data/projects_gen.yaml
fi

echo "==> Generating starred repos data"
if [[ -n "${FORGE_TOKENS:-}" ]] && [[ "${FORGE_TOKENS}" != '{"github.com": ""}' ]]; then
    if /app/pkg/ps-gen-starred -forges /app/data/site/data/forges.yaml -username "${GITHUB_USERNAME:-rmdes}" -limit 30 > /app/data/site/data/starred_gen.yaml; then
        echo "    Starred repos generated successfully"
    else
        echo "Warning: Failed to generate starred repos"
        echo "[]" > /app/data/site/data/starred_gen.yaml
    fi
else
    echo "Warning: FORGE_TOKENS not configured, skipping starred repos generation"
    echo "[]" > /app/data/site/data/starred_gen.yaml
fi

# Ensure proper ownership
chown -R cloudron:cloudron /app/data

echo "==> Starting application server"
cd /app/data/site
exec gosu cloudron:cloudron /app/pkg/ps-proxy \
    -laddr="0.0.0.0:8000" \
    -scmd='hugo server --baseURL=/ --appendPort=false --bind=127.0.0.1 --port=1313' \
    -surl='http://127.0.0.1:1313/' \
    -acmd='/app/pkg/ps-api' \
    -aurl='http://127.0.0.1:1314/'
