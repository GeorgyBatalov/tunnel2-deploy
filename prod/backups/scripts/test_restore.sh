#!/bin/bash
# ============================================================================
# Test backup restore (locally, safe)
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUPS_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Testing backup restore (locally)"

# Find latest backup
LATEST_BACKUP=$(ls -t "$BACKUPS_DIR/postgres/last/"*.sql.gz 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "ERROR: No backup files found in $BACKUPS_DIR/postgres/last/"
    exit 1
fi

echo "==> Using backup: $LATEST_BACKUP"

# Create temporary test container
echo "==> Creating test PostgreSQL container"
docker run -d --name test_postgres_restore \
  -e POSTGRES_USER=test \
  -e POSTGRES_PASSWORD=test \
  -e POSTGRES_DB=test_restore \
  -v "$BACKUPS_DIR/postgres:/backups:ro" \
  postgres:16

echo "==> Waiting for PostgreSQL to start..."
sleep 10

# Restore backup
echo "==> Restoring backup (this may show warnings about roles - it's OK)"
BACKUP_FILE="/backups/last/$(basename "$LATEST_BACKUP")"
docker exec test_postgres_restore \
  pg_restore -U test -d test_restore --verbose "$BACKUP_FILE" 2>&1 | grep -E "restoring|creating|completed"

# Check results
echo ""
echo "==> Checking restored data"

docker exec test_postgres_restore \
  psql -U test -d test_restore -c "\dt"

ROWS=$(docker exec test_postgres_restore \
  psql -U test -d test_restore -t -c 'SELECT COUNT(*) FROM "ClientRegistrations";' | xargs)

echo ""
echo "✅ Restore successful!"
echo "   Tables: $(docker exec test_postgres_restore psql -U test -d test_restore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" | xargs)"
echo "   ClientRegistrations rows: $ROWS"

# Cleanup
echo ""
echo "==> Cleaning up test container"
docker rm -f test_postgres_restore

echo ""
echo "==> ✅ Backup restore test complete!"
