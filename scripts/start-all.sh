#!/bin/bash

# Complete Tunnel2 Deployment Script
# Запускает всю инфраструктуру: Vault + Infrastructure + Applications

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
DEV_DIR="$DEPLOY_DIR/dev"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Tunnel2 Complete Deployment Script  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Step 0: Stop any old containers from previous compose files
echo -e "${YELLOW}🧹 Step 0/5: Ensuring clean state...${NC}"
cd "$DEV_DIR"

# Останавливаем старые compose проекты если они есть
# Это безопасно - compose просто скажет "not found" если их нет
docker compose -f docker-compose.yml down 2>/dev/null || true
docker compose -f docker-compose-infrastructure.yml down 2>/dev/null || true

# Останавливаем все tunnel2 контейнеры из предыдущих запусков
TUNNEL_CONTAINERS=$(docker ps -a --filter "name=tunnel2" --format "{{.Names}}" 2>/dev/null || true)
if [ ! -z "$TUNNEL_CONTAINERS" ]; then
    echo "  Stopping old tunnel2 containers..."
    echo "$TUNNEL_CONTAINERS" | xargs -r docker rm -f 2>/dev/null || true
fi

# Удаляем любые осиротевшие контейнеры с конфликтующими именами
for container in vault; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "  Removing old container: $container"
        docker rm -f "$container" 2>/dev/null || true
    fi
done

echo "  Ready for deployment"
echo ""

# Step 1: Start Infrastructure
echo -e "${YELLOW}📦 Step 1/5: Starting infrastructure services...${NC}"
echo "  - Vault"
echo "  - Redis"
echo "  - RabbitMQ"
echo "  - PostgreSQL"
echo ""

cd "$DEV_DIR"
docker compose -f docker-compose-infrastructure.yml up -d

echo -e "${GREEN}✅ Infrastructure services started${NC}"
echo ""

# Step 2: Wait for services to be ready
echo -e "${YELLOW}⏳ Step 2/5: Waiting for services to be ready...${NC}"
sleep 5
echo -e "${GREEN}✅ Services ready${NC}"
echo ""

# Step 3: Unseal Vault
echo -e "${YELLOW}🔓 Step 3/5: Unsealing Vault...${NC}"
"$SCRIPT_DIR/vault-unseal.sh"
echo ""

# Step 4: Start Tunnel2 Applications
echo -e "${YELLOW}🚀 Step 4/5: Starting Tunnel2 applications...${NC}"
echo "  - TunnelServer (Control Plane)"
echo "  - ProxyEntry (Data Plane)"
echo "  - Test Backend"
echo "  - Httpbin"
echo ""

cd "$DEV_DIR"
docker compose -f docker-compose.yml up -d --build

echo -e "${GREEN}✅ Tunnel2 applications started${NC}"
echo ""

# Step 5: Show status
echo -e "${YELLOW}📊 Step 5/5: Checking services status...${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Deployment Complete! ✨${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
echo "Services status:"
docker compose -f docker-compose-infrastructure.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""
docker compose -f docker-compose.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo -e "${YELLOW}Available endpoints:${NC}"
echo "  - Vault UI:        http://localhost:8200"
echo "  - RabbitMQ UI:     http://localhost:15672 (guest/guest)"
echo "  - ProxyEntry HTTP: http://localhost:12000"
echo "  - TunnelServer:    http://localhost:12002"
echo "  - Test Backend:    http://localhost:12007"
echo "  - Httpbin:         http://localhost:12005"
echo ""
echo -e "${GREEN}Ready for integration tests! 🎉${NC}"
