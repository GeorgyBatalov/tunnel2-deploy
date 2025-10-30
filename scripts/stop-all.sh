#!/bin/bash

# Stop all Tunnel2 services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
DEV_DIR="$DEPLOY_DIR/dev"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🛑 Stopping all Tunnel2 services...${NC}"
echo ""

cd "$DEV_DIR"

# Stop applications first
echo "Stopping applications..."
docker compose -f docker-compose.yml down

# Stop infrastructure
echo "Stopping infrastructure..."
docker compose -f docker-compose-infrastructure.yml down

echo ""
echo -e "${GREEN}✅ All services stopped${NC}"
echo ""
echo -e "${YELLOW}Note: Vault data is preserved in Docker volume 'tunnel2_vault-data'${NC}"
echo "To completely remove all data, run:"
echo "  docker volume rm tunnel2_vault-data tunnel2_postgres-data"
