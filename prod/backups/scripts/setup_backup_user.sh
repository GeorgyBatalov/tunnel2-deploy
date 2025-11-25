#!/bin/bash
# ============================================================================
# Setup PostgreSQL backup_user
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUPS_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Setting up PostgreSQL backup_user"

# Load environment
if [ ! -f "$BACKUPS_DIR/.env" ]; then
    echo "ERROR: .env file not found at $BACKUPS_DIR/.env"
    echo "Please copy .env.example to .env and fill in the values"
    exit 1
fi

source "$BACKUPS_DIR/.env"

if [ -z "$POSTGRES_BACKUP_PASSWORD" ]; then
    echo "ERROR: POSTGRES_BACKUP_PASSWORD not set in .env"
    exit 1
fi

echo "==> Creating backup_user in PostgreSQL"
BACKUP_PASSWORD="$POSTGRES_BACKUP_PASSWORD" docker exec -i postgres \
  psql -U tunnel -d tunnel2 \
  -v BACKUP_PASSWORD="$POSTGRES_BACKUP_PASSWORD" \
  < "$SCRIPT_DIR/create_backup_user.sql"

echo ""
echo "==> Verifying backup_user permissions"

# Test SELECT (should work)
echo "Testing SELECT permission..."
PGPASSWORD="$POSTGRES_BACKUP_PASSWORD" docker exec -e PGPASSWORD postgres \
  psql -U backup_user -d tunnel2 -c "SELECT COUNT(*) FROM \"ClientRegistrations\";" \
  && echo "✅ SELECT works"

# Test INSERT (should fail)
echo ""
echo "Testing INSERT permission (should fail)..."
PGPASSWORD="$POSTGRES_BACKUP_PASSWORD" docker exec -e PGPASSWORD postgres \
  psql -U backup_user -d tunnel2 -c "INSERT INTO \"ClientRegistrations\" (\"HardwareThumbprint\", \"SecretKey\", \"Tier\", \"CreatedAt\") VALUES ('test', 'test', 'free', NOW());" \
  2>&1 | grep -q "permission denied" \
  && echo "✅ INSERT correctly denied" \
  || echo "⚠️  WARNING: INSERT should be denied!"

echo ""
echo "==> ✅ backup_user setup complete!"
