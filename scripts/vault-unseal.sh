#!/bin/bash

# Vault Unseal Script
# Автоматически распечатывает Vault используя ключи из vault-keys.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
VAULT_KEYS_FILE="$DEPLOY_DIR/vault-keys.json"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔓 Vault Unseal Script"
echo "======================"

# Проверяем наличие файла с ключами
if [ ! -f "$VAULT_KEYS_FILE" ]; then
    echo -e "${RED}❌ Error: vault-keys.json not found at $VAULT_KEYS_FILE${NC}"
    echo "Please ensure vault-keys.json exists in tunnel2-deploy/"
    exit 1
fi

# Проверяем что jq установлен
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ Error: jq is not installed${NC}"
    echo "Install with: brew install jq"
    exit 1
fi

# Проверяем что контейнер Vault запущен
if ! docker ps --format '{{.Names}}' | grep -q "^vault$"; then
    echo -e "${RED}❌ Error: Vault container is not running${NC}"
    echo "Start it with: cd $DEPLOY_DIR/dev && docker compose -f docker-compose-infrastructure.yml up -d vault"
    exit 1
fi

echo -e "${YELLOW}⏳ Waiting for Vault to be ready...${NC}"
sleep 3

# Проверяем статус Vault
VAULT_STATUS=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault status -format=json 2>/dev/null || echo '{"sealed":true,"initialized":false}')
SEALED=$(echo "$VAULT_STATUS" | jq -r '.sealed')
INITIALIZED=$(echo "$VAULT_STATUS" | jq -r '.initialized')

echo "Vault Status:"
echo "  - Initialized: $INITIALIZED"
echo "  - Sealed: $SEALED"
echo ""

if [ "$INITIALIZED" = "false" ]; then
    echo -e "${RED}❌ Vault is not initialized yet${NC}"
    echo "Run: docker exec -it vault vault operator init"
    exit 1
fi

if [ "$SEALED" = "false" ]; then
    echo -e "${GREEN}✅ Vault is already unsealed!${NC}"
    exit 0
fi

# Читаем ключи из JSON
echo -e "${YELLOW}🔑 Reading unseal keys from vault-keys.json...${NC}"
KEYS=$(jq -r '.keys_base64[]' "$VAULT_KEYS_FILE")

# Для unseal нужно 3 ключа из 5
KEY_COUNT=0
for KEY in $KEYS; do
    KEY_COUNT=$((KEY_COUNT + 1))
    if [ $KEY_COUNT -le 3 ]; then
        echo "  Applying key $KEY_COUNT/3..."
        docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault operator unseal "$KEY" > /dev/null 2>&1
    fi
done

echo ""

# Проверяем результат
VAULT_STATUS=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 vault vault status -format=json 2>/dev/null || echo '{"sealed":true}')
SEALED=$(echo "$VAULT_STATUS" | jq -r '.sealed')

if [ "$SEALED" = "false" ]; then
    echo -e "${GREEN}✅ Vault successfully unsealed!${NC}"
    echo ""
    echo "Root token: $(jq -r '.root_token' "$VAULT_KEYS_FILE")"
    echo ""
    echo "You can now access Vault UI at: http://localhost:8200"
    exit 0
else
    echo -e "${RED}❌ Failed to unseal Vault${NC}"
    exit 1
fi
