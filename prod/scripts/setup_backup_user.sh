#!/bin/bash
# ============================================================================
# Setup PostgreSQL Backup User (Read-Only)
# ============================================================================
#
# This script creates a read-only backup user in PostgreSQL
#
# Usage:
#   ./setup_backup_user.sh
#
# Prerequisites:
#   - PostgreSQL container (tunnel2_postgres) must be running
#   - POSTGRES_BACKUP_PASSWORD must be set in .env
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "PostgreSQL Backup User Setup"
echo "=========================================="
echo ""

# Check if .env exists
if [ ! -f "../.env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create .env from .env.template first."
    exit 1
fi

# Load .env
source ../.env

# Check if POSTGRES_BACKUP_PASSWORD is set
if [ -z "$POSTGRES_BACKUP_PASSWORD" ]; then
    echo -e "${RED}Error: POSTGRES_BACKUP_PASSWORD is not set in .env${NC}"
    echo ""
    echo "Generate a secure password:"
    echo "  openssl rand -base64 32"
    echo ""
    echo "Then add to .env:"
    echo "  POSTGRES_BACKUP_PASSWORD=<your_generated_password>"
    exit 1
fi

# Check if PostgreSQL container is running
if ! docker ps | grep -q tunnel2_postgres; then
    echo -e "${RED}Error: PostgreSQL container (tunnel2_postgres) is not running${NC}"
    echo "Start it with: make infra-up"
    exit 1
fi

echo "Creating backup_user..."
docker exec -i tunnel2_postgres psql -U "$POSTGRES_USER" -d tunnel2 <<EOF
-- Create backup user
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'backup_user') THEN
    CREATE USER backup_user WITH PASSWORD '$POSTGRES_BACKUP_PASSWORD';
    RAISE NOTICE 'User backup_user created';
  ELSE
    RAISE NOTICE 'User backup_user already exists';
  END IF;
END
\$\$;

-- Grant permissions
GRANT CONNECT ON DATABASE tunnel2 TO backup_user;
GRANT USAGE ON SCHEMA public TO backup_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO backup_user;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO backup_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO backup_user;

\echo 'Permissions granted'
EOF

echo ""
echo -e "${GREEN}✓ backup_user created successfully${NC}"
echo ""

# Test backup user permissions
echo "Testing backup_user permissions..."
echo ""

# Test 1: SELECT should work
echo "Test 1: SELECT (should work)..."
docker exec tunnel2_postgres psql -U backup_user -d tunnel2 -c "SELECT 1 AS test;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SELECT works${NC}"
else
    echo -e "${RED}✗ SELECT failed${NC}"
    exit 1
fi

# Test 2: CREATE TABLE should fail
echo "Test 2: CREATE TABLE (should fail)..."
docker exec tunnel2_postgres psql -U backup_user -d tunnel2 -c "CREATE TABLE test_fail (id INT);" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${GREEN}✓ CREATE TABLE denied (as expected)${NC}"
else
    echo -e "${RED}✗ CREATE TABLE allowed (security issue!)${NC}"
    exit 1
fi

# Test 3: pg_dump should work
echo "Test 3: pg_dump (should work)..."
docker exec tunnel2_postgres pg_dump -U backup_user -d tunnel2 --format=custom > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ pg_dump works${NC}"
else
    echo -e "${RED}✗ pg_dump failed${NC}"
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}All tests passed!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Start backup services: make backup-up"
echo "  2. Check logs: make backup-logs"
echo "  3. Test backup: make backup-test"
echo ""
