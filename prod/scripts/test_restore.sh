#!/bin/bash
# ============================================================================
# Test PostgreSQL Backup Restore
# ============================================================================
#
# This script tests that backups can be restored successfully
#
# Usage:
#   ./test_restore.sh [backup_file]
#
# If no backup file specified, uses the latest local backup
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "PostgreSQL Backup Restore Test"
echo "=========================================="
echo ""

# Find backup file
if [ -n "$1" ]; then
    BACKUP_FILE="$1"
else
    BACKUP_FILE=$(ls -t ../backups/postgres/*.dump 2>/dev/null | head -1)
fi

if [ -z "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: No backup files found in ../backups/postgres/${NC}"
    echo "Run 'make backup-now' first"
    exit 1
fi

echo "Using backup: $(basename $BACKUP_FILE)"
echo "Size: $(du -h $BACKUP_FILE | cut -f1)"
echo ""

# Create temporary test container
echo "Creating test PostgreSQL container..."
docker rm -f test_postgres_restore 2>/dev/null || true
docker run --name test_postgres_restore -d \
    -e POSTGRES_USER=test \
    -e POSTGRES_PASSWORD=test \
    -e POSTGRES_DB=test_restore \
    postgres:16 > /dev/null

# Wait for PostgreSQL to start
echo "Waiting for PostgreSQL to start..."
sleep 5

# Restore backup
echo "Restoring backup..."
docker exec -i test_postgres_restore \
    pg_restore -U test -d test_restore --verbose --no-owner --no-acl < "$BACKUP_FILE" 2>&1 | tail -10

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Restore failed!${NC}"
    docker rm -f test_postgres_restore
    exit 1
fi

echo ""
echo "Verifying restored data..."

# Check if tables exist
TABLE_COUNT=$(docker exec test_postgres_restore \
    psql -U test -d test_restore -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';" | tr -d ' ')

echo "Tables restored: $TABLE_COUNT"

if [ "$TABLE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠ No tables found (database might be empty)${NC}"
else
    echo -e "${GREEN}✓ Tables restored successfully${NC}"
fi

# Show table list
echo ""
echo "Tables in restored database:"
docker exec test_postgres_restore \
    psql -U test -d test_restore -c "\dt"

# Cleanup
echo ""
echo "Cleaning up test container..."
docker rm -f test_postgres_restore > /dev/null

echo ""
echo "=========================================="
echo -e "${GREEN}✅ Restore test completed!${NC}"
echo "=========================================="
echo ""
echo "Backup file: $(basename $BACKUP_FILE)"
echo "Tables restored: $TABLE_COUNT"
echo ""
