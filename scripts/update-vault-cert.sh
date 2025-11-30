#!/bin/bash

# Update Vault TunnelClientTls Certificate Script
# Обновляет Vault с новой структурой TunnelClientTls (base64-encoded cert + password)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Update Vault TunnelClientTls Cert   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Параметры
CERT_PATH="$1"
CERT_PASSWORD="$2"
VAULT_TOKEN="$3"

if [ -z "$CERT_PATH" ] || [ -z "$CERT_PASSWORD" ]; then
    echo -e "${RED}Usage: $0 <cert_path> <cert_password> [vault_token]${NC}"
    echo ""
    echo "Examples:"
    echo "  Dev:  $0 tunnel2-server/src/Tunnel2.TunnelServer.ConsoleApp/cert.pfx 1234"
    echo "  Prod: $0 tunnel2-deploy/prod/certs/server.pfx <password> <vault_token>"
    echo ""
    exit 1
fi

# Проверяем наличие сертификата
if [ ! -f "$CERT_PATH" ]; then
    echo -e "${RED}❌ Error: Certificate not found: $CERT_PATH${NC}"
    exit 1
fi

# Проверяем что контейнер Vault запущен
if ! docker ps --format '{{.Names}}' | grep -q "^vault$"; then
    echo -e "${RED}❌ Error: Vault container is not running${NC}"
    echo "Start it with: cd $DEPLOY_DIR/dev && docker compose -f docker-compose-infrastructure.yml up -d vault"
    exit 1
fi

echo -e "${YELLOW}📋 Configuration:${NC}"
echo "  Certificate: $CERT_PATH"
echo "  Password: ${CERT_PASSWORD:0:1}*** (hidden)"
echo ""

# Если токен не указан, берем из vault-keys.json
if [ -z "$VAULT_TOKEN" ]; then
    VAULT_KEYS_FILE="$DEPLOY_DIR/vault-keys.json"
    if [ -f "$VAULT_KEYS_FILE" ]; then
        if command -v jq &> /dev/null; then
            VAULT_TOKEN=$(jq -r '.root_token' "$VAULT_KEYS_FILE")
            echo -e "${YELLOW}🔑 Using Vault token from vault-keys.json${NC}"
        else
            echo -e "${RED}❌ Error: jq is not installed (needed to read vault-keys.json)${NC}"
            echo "Install with: brew install jq"
            echo "Or provide vault token manually: $0 <cert> <password> <token>"
            exit 1
        fi
    else
        echo -e "${RED}❌ Error: No Vault token provided and vault-keys.json not found${NC}"
        echo "Provide token: $0 <cert> <password> <token>"
        exit 1
    fi
fi

# Проверяем статус Vault
echo -e "${YELLOW}🔍 Checking Vault status...${NC}"
VAULT_STATUS=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="$VAULT_TOKEN" vault sh -c 'vault status -format=json' 2>/dev/null || echo '{"sealed":true}')
SEALED=$(echo "$VAULT_STATUS" | jq -r '.sealed' 2>/dev/null || echo "true")

if [ "$SEALED" = "true" ]; then
    echo -e "${RED}❌ Vault is sealed!${NC}"
    echo "Run: $DEPLOY_DIR/scripts/vault-unseal.sh"
    exit 1
fi

echo -e "${GREEN}✅ Vault is unsealed${NC}"
echo ""

# Кодируем сертификат в base64
echo -e "${YELLOW}📦 Encoding certificate to base64...${NC}"
CERT_BASE64=$(base64 -i "$CERT_PATH" | tr -d '\n')
CERT_SIZE=${#CERT_BASE64}
echo "  Size: $CERT_SIZE bytes"
echo ""

# Создаем временный JSON файл
TMP_JSON="/tmp/vault-tls-$$.json"
cat > "$TMP_JSON" <<EOF
{
  "TunnelClientTls": {
    "CertificateData": "$CERT_BASE64",
    "CertificatePassword": "$CERT_PASSWORD"
  }
}
EOF

echo -e "${YELLOW}📤 Uploading to Vault...${NC}"

# Копируем JSON в контейнер
docker cp "$TMP_JSON" vault:/tmp/vault-tls.json

# Обновляем Vault
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="$VAULT_TOKEN" vault sh -c \
    'vault kv patch kv/tunnel/tunnel-server @/tmp/vault-tls.json'

# Удаляем временные файлы
rm -f "$TMP_JSON"
docker exec vault rm -f /tmp/vault-tls.json

echo ""
echo -e "${GREEN}✅ Certificate uploaded successfully!${NC}"
echo ""

# Проверяем что данные сохранились
echo -e "${YELLOW}🔍 Verifying...${NC}"
VERIFY_RESULT=$(docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="$VAULT_TOKEN" vault sh -c \
    'vault kv get -format=json kv/tunnel/tunnel-server' | jq -r '.data.data.TunnelClientTls.CertificatePassword' 2>/dev/null || echo "")

if [ "$VERIFY_RESULT" = "$CERT_PASSWORD" ]; then
    echo -e "${GREEN}✅ Verification successful - TunnelClientTls configured correctly${NC}"
else
    echo -e "${RED}❌ Verification failed - TunnelClientTls not found in Vault${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Done! ✨${NC}"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
