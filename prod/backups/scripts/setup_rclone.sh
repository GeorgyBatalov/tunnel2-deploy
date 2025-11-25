#!/bin/bash
# ============================================================================
# Setup rclone for Yandex.Disk via WebDAV
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUPS_DIR="$(dirname "$SCRIPT_DIR")"
RCLONE_DIR="$BACKUPS_DIR/rclone"

echo "==> Setting up rclone for Yandex.Disk"

# Load environment
if [ ! -f "$BACKUPS_DIR/.env" ]; then
    echo "ERROR: .env file not found at $BACKUPS_DIR/.env"
    echo "Please copy .env.example to .env and fill in the values"
    exit 1
fi

source "$BACKUPS_DIR/.env"

if [ -z "$YANDEX_USERNAME" ] || [ -z "$YANDEX_APP_PASSWORD" ]; then
    echo "ERROR: YANDEX_USERNAME or YANDEX_APP_PASSWORD not set in .env"
    echo "Get app password from: https://id.yandex.ru/security/app-passwords"
    exit 1
fi

echo "==> Creating rclone directory"
mkdir -p "$RCLONE_DIR"

echo "==> Obscuring Yandex password"
OBSCURED_PASSWORD=$(docker run --rm rclone/rclone:1.65 obscure "$YANDEX_APP_PASSWORD")

echo "==> Creating rclone.conf"
docker run --rm -v "$RCLONE_DIR:/config/rclone" --entrypoint=/bin/sh rclone/rclone:1.65 -c "
cat > /config/rclone/rclone.conf << EOF
[yandex]
type = webdav
url = https://webdav.yandex.ru
vendor = other
user = $YANDEX_USERNAME
pass = $OBSCURED_PASSWORD
EOF
chmod 600 /config/rclone/rclone.conf
"

echo ""
echo "==> Testing rclone connection"

# List remotes
docker run --rm -v "$RCLONE_DIR:/config/rclone" rclone/rclone:1.65 listremotes \
  && echo "✅ rclone remote configured"

# Test connection
docker run --rm -v "$RCLONE_DIR:/config/rclone" rclone/rclone:1.65 lsd yandex: \
  && echo "✅ Connection to Yandex.Disk works"

# Create backup folder
echo ""
echo "==> Creating xtunnel-backups folder on Yandex.Disk"
docker run --rm -v "$RCLONE_DIR:/config/rclone" rclone/rclone:1.65 mkdir yandex:xtunnel-backups 2>/dev/null || true

docker run --rm -v "$RCLONE_DIR:/config/rclone" rclone/rclone:1.65 lsd yandex: | grep xtunnel-backups \
  && echo "✅ xtunnel-backups folder exists"

echo ""
echo "==> ✅ rclone setup complete!"
echo ""
echo "Test with:"
echo "  docker run --rm -v $RCLONE_DIR:/config/rclone rclone/rclone:1.65 size yandex:xtunnel-backups"
