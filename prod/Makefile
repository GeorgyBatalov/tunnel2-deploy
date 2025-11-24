# ===================================================================
# Tunnel2 Production Deployment Makefile
# ===================================================================
# Usage:
#   make init          - Initialize .env file from template
#   make pull          - Pull latest code from GitHub
#   make build         - Build Docker images
#   make infra-up      - Start infrastructure services
#   make infra-down    - Stop infrastructure services
#   make services-up   - Start tunnel2 services
#   make services-down - Stop tunnel2 services
#   make up            - Start all services (infra + services)
#   make down          - Stop all services
#   make restart       - Restart all services
#   make logs          - Show logs
#   make ps            - Show running containers
#   make health        - Check health of all services
#   make clean         - Remove all containers and volumes (DANGEROUS!)
# ===================================================================

.PHONY: help init pull build infra-up infra-down services-up services-down up down restart logs ps health vault-init clean

# Colors
GREEN=\033[0;32m
YELLOW=\033[1;33m
RED=\033[0;31m
NC=\033[0m

# Default target
help:
	@echo "Tunnel2 Production Deployment"
	@echo "=============================="
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  make deploy        - Full deployment (pull + build + up + wait)"
	@echo ""
	@echo "📦 Setup:"
	@echo "  make init          - Initialize .env file from template"
	@echo "  make pull          - Pull latest code from GitHub"
	@echo "  make build         - Build Docker images (or pull from registry)"
	@echo ""
	@echo "🔧 Service Control:"
	@echo "  make infra-up      - Start infrastructure services"
	@echo "  make infra-down    - Stop infrastructure services"
	@echo "  make services-up   - Start tunnel2 services"
	@echo "  make services-down - Stop tunnel2 services"
	@echo "  make up            - Start all services (infra + services)"
	@echo "  make down          - Stop all services"
	@echo "  make restart       - Restart all services"
	@echo ""
	@echo "📊 Monitoring:"
	@echo "  make logs          - Show logs (all services)"
	@echo "  make ps            - Show running containers"
	@echo "  make health        - Check health of all services"
	@echo "  make wait          - Wait for all services to be healthy"
	@echo ""
	@echo "🔐 Vault:"
	@echo "  make vault-init    - Initialize Vault (run once)"
	@echo "  make vault-unseal  - Unseal Vault (interactive)"
	@echo "  make vault-status  - Check Vault status"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  make clean         - Remove all containers and volumes (DANGEROUS!)"
	@echo ""

# Initialize .env file from template
init:
	@if [ ! -f .env ]; then \
		cp .env.template .env; \
		echo "✓ Created .env file from template"; \
		echo "⚠️  IMPORTANT: Edit .env and set all CHANGE_ME values!"; \
	else \
		echo "✗ .env file already exists"; \
	fi

# Pull latest code from GitHub
pull:
	@echo "Pulling latest code from GitHub..."
	cd ../.. && git pull origin main
	cd ../.. && git submodule update --remote --recursive
	@echo "✓ Code updated"

# Build Docker images
build:
	@echo "Building Docker images..."
	docker compose -f infrastructure.docker-compose.yml build
	docker compose -f services.docker-compose.yml build
	@echo "✓ Images built"

# Start infrastructure services
infra-up:
	@echo "🚀 Starting infrastructure services..."
	docker compose -f infrastructure.docker-compose.yml up -d
	@echo -e "$(GREEN)✓$(NC) Infrastructure services started"
	@echo "⏳ Waiting for services to be healthy..."
	@sleep 15
	@make health

# Stop infrastructure services
infra-down:
	@echo "Stopping infrastructure services..."
	docker compose -f infrastructure.docker-compose.yml down
	@echo "✓ Infrastructure services stopped"

# Start tunnel2 services
services-up:
	@echo "🚀 Starting tunnel2 services..."
	docker compose -f services.docker-compose.yml up -d
	@echo -e "$(GREEN)✓$(NC) Tunnel2 services started"
	@sleep 10
	@make health

# Stop tunnel2 services
services-down:
	@echo "Stopping tunnel2 services..."
	docker compose -f services.docker-compose.yml down
	@echo "✓ Tunnel2 services stopped"

# Start all services (infra + services)
up: infra-up services-up
	@echo "✓ All services started"

# Stop all services
down: services-down infra-down
	@echo "✓ All services stopped"

# Restart all services
restart: down up
	@echo "✓ All services restarted"

# Show logs (all services)
logs:
	@echo "Showing logs (Ctrl+C to exit)..."
	docker compose -f infrastructure.docker-compose.yml logs -f &
	docker compose -f services.docker-compose.yml logs -f

# Show logs for specific service
logs-infra:
	docker compose -f infrastructure.docker-compose.yml logs -f

logs-services:
	docker compose -f services.docker-compose.yml logs -f

# Show running containers
ps:
	@echo "Infrastructure services:"
	@docker compose -f infrastructure.docker-compose.yml ps
	@echo ""
	@echo "Tunnel2 services:"
	@docker compose -f services.docker-compose.yml ps

# Check health of all services
health:
	@echo "🔍 Checking health of all services..."
	@echo ""
	@echo "=== Infrastructure ==="
	@docker ps --filter "name=tunnel2_" --format "table {{.Names}}\t{{.Status}}" | grep -E "(NAMES|vault|redis|rabbitmq|postgres|opensearch|prometheus|grafana)" || true
	@echo ""
	@echo "=== Services ==="
	@docker ps --filter "name=tunnel2_" --format "table {{.Names}}\t{{.Status}}" | grep -E "(NAMES|tunnel2_server|tunnel2_entry)" || true
	@echo ""
	@echo "=== Health Checks ==="
	@curl -f http://localhost:12003/health/live > /dev/null 2>&1 && echo -e "$(GREEN)✓$(NC) tunnel2_server: healthy" || echo -e "$(RED)✗$(NC) tunnel2_server: unhealthy"
	@curl -f http://localhost:9091/-/healthy > /dev/null 2>&1 && echo -e "$(GREEN)✓$(NC) prometheus: healthy" || echo -e "$(RED)✗$(NC) prometheus: unhealthy"
	@curl -f http://localhost:3001/api/health > /dev/null 2>&1 && echo -e "$(GREEN)✓$(NC) grafana: healthy" || echo -e "$(RED)✗$(NC) grafana: unhealthy"
	@curl -f http://localhost:9201/_cluster/health > /dev/null 2>&1 && echo -e "$(GREEN)✓$(NC) opensearch: healthy" || echo -e "$(RED)✗$(NC) opensearch: unhealthy"

# Wait for all services to be healthy (with timeouts like in start-integration-env.sh)
wait:
	@echo "⏳ Waiting for services to be healthy (this may take 60-90 seconds)..."
	@echo ""
	@echo -n "  - Waiting for postgres... "
	@timeout 60 bash -c 'until docker exec tunnel2_postgres pg_isready -U $(POSTGRES_USER) >/dev/null 2>&1; do sleep 2; done' && echo -e "$(GREEN)✓$(NC)" || echo -e "$(RED)✗$(NC)"
	@echo -n "  - Waiting for redis... "
	@timeout 30 bash -c 'until docker exec tunnel2_redis redis-cli ping >/dev/null 2>&1; do sleep 2; done' && echo -e "$(GREEN)✓$(NC)" || echo -e "$(RED)✗$(NC)"
	@echo -n "  - Waiting for rabbitmq... "
	@timeout 60 bash -c 'until docker exec tunnel2_rabbitmq rabbitmq-diagnostics ping >/dev/null 2>&1; do sleep 3; done' && echo -e "$(GREEN)✓$(NC)" || echo -e "$(RED)✗$(NC)"
	@echo -n "  - Waiting for opensearch... "
	@timeout 90 bash -c 'until curl -sf http://localhost:9201/_cluster/health >/dev/null 2>&1; do sleep 3; done' && echo -e "$(GREEN)✓$(NC)" || echo -e "$(RED)✗$(NC)"
	@echo -n "  - Waiting for tunnel2_server... "
	@timeout 60 bash -c 'until curl -sf http://localhost:12003/health/live >/dev/null 2>&1; do sleep 3; done' && echo -e "$(GREEN)✓$(NC)" || echo -e "$(RED)✗$(NC)"
	@echo ""
	@echo -e "$(GREEN)✅ All services are healthy!$(NC)"

# Initialize Vault (run once after first deployment)
vault-init:
	@echo "🔐 Initializing Vault..."
	@echo -e "$(YELLOW)⚠️  SAVE THE OUTPUT IN A SECURE LOCATION!$(NC)"
	@echo ""
	docker exec -it tunnel2_vault vault operator init
	@echo ""
	@echo "Next steps:"
	@echo "1. Unseal Vault: make vault-unseal"
	@echo "2. Update .env file with VAULT_ROOT_TOKEN"
	@echo "3. Restart services: make restart"

# Unseal Vault (interactive, needs 3 unseal keys)
vault-unseal:
	@echo "🔓 Unsealing Vault (requires 3 of 5 unseal keys)..."
	@echo ""
	@echo "Enter unseal key 1:"
	@read -s key1 && docker exec -it tunnel2_vault vault operator unseal $$key1
	@echo ""
	@echo "Enter unseal key 2:"
	@read -s key2 && docker exec -it tunnel2_vault vault operator unseal $$key2
	@echo ""
	@echo "Enter unseal key 3:"
	@read -s key3 && docker exec -it tunnel2_vault vault operator unseal $$key3
	@echo ""
	@echo -e "$(GREEN)✓$(NC) Vault unsealed"

# Check Vault status
vault-status:
	@echo "🔐 Vault Status:"
	@docker exec tunnel2_vault vault status || true

# ===== Backup Management =====

# Setup backup user (run once)
backup-setup:
	@echo "💾 Setting up PostgreSQL backup user..."
	@cd scripts && ./setup_backup_user.sh

# Configure rclone for Yandex.Disk (interactive)
backup-config-rclone:
	@echo "☁️  Configuring rclone for Yandex.Disk..."
	@mkdir -p rclone
	@docker run -it --rm -v $(PWD)/rclone:/config/rclone rclone/rclone:1.65 config
	@chmod 600 rclone/rclone.conf
	@echo -e "$(GREEN)✓$(NC) rclone configured"
	@echo ""
	@echo "Test connection: make backup-test-rclone"

# Test rclone connection
backup-test-rclone:
	@echo "Testing rclone connection to Yandex.Disk..."
	@docker run --rm -v $(PWD)/rclone:/config/rclone rclone/rclone:1.65 lsd yandex:
	@echo -e "$(GREEN)✓$(NC) Connection successful"

# Start backup services
backup-up:
	@echo "Starting backup services..."
	@docker compose -f infrastructure.docker-compose.yml up -d postgres_backup rclone_upload
	@echo -e "$(GREEN)✓$(NC) Backup services started"
	@echo ""
	@echo "Check logs: make backup-logs"

# Stop backup services
backup-down:
	@echo "Stopping backup services..."
	@docker compose -f infrastructure.docker-compose.yml stop postgres_backup rclone_upload
	@echo -e "$(GREEN)✓$(NC) Backup services stopped"

# Show backup logs
backup-logs:
	@echo "=== PostgreSQL Backup Logs ==="
	@docker logs --tail=50 tunnel2_postgres_backup
	@echo ""
	@echo "=== Rclone Upload Logs ==="
	@docker logs --tail=50 tunnel2_rclone_upload

# Trigger backup manually (don't wait for schedule)
backup-now:
	@echo "Triggering manual backup..."
	@docker exec tunnel2_postgres_backup /backup.sh
	@echo ""
	@echo "Check status: make backup-status"

# Show backup status
backup-status:
	@echo "=== Local Backups ==="
	@ls -lh backups/postgres/ 2>/dev/null || echo "No backups yet"
	@echo ""
	@echo "=== Yandex.Disk Backups ==="
	@docker run --rm -v $(PWD)/rclone:/config/rclone rclone/rclone:1.65 ls yandex:xtunnel-backups 2>/dev/null || echo "No backups on Yandex.Disk yet"
	@echo ""
	@echo "=== Container Status ==="
	@docker ps --filter "name=backup\|rclone" --format "table {{.Names}}\t{{.Status}}\t{{.State}}"

# Test backup restore (creates temporary container)
backup-test-restore:
	@echo "⚠️  Testing backup restore (this will create a temporary PostgreSQL container)..."
	@echo ""
	@bash scripts/test_restore.sh

# Clean old backups manually
backup-clean:
	@echo "Cleaning old local backups (>7 days)..."
	@find backups/postgres/ -name "*.dump" -mtime +7 -delete
	@echo -e "$(GREEN)✓$(NC) Old backups cleaned"

# Full backup setup (interactive)
backup-init: backup-setup backup-config-rclone backup-up
	@echo ""
	@echo -e "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo -e "$(GREEN)✅ Backup system initialized!$(NC)"
	@echo -e "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Test backup now: make backup-now"
	@echo "  2. Check status: make backup-status"
	@echo "  3. Test restore: make backup-test-restore"
	@echo ""

# Clean all containers and volumes (DANGEROUS!)
clean:
	@echo "⚠️  WARNING: This will remove all containers and volumes!"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@echo "Removing all services and volumes..."
	docker compose -f services.docker-compose.yml down -v
	docker compose -f infrastructure.docker-compose.yml down -v
	@echo "✓ All services and volumes removed"

# Deploy full stack (pull + build + up + wait)
deploy: pull build up wait
	@echo ""
	@echo -e "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo -e "$(GREEN)✅ Full deployment complete!$(NC)"
	@echo -e "$(GREEN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"
	@echo ""
	@echo "📋 Service endpoints:"
	@echo "  - TunnelServer Control Plane: :12002 (TLS)"
	@echo "  - TunnelServer HTTP API: http://localhost:12003"
	@echo "  - TunnelServer Metrics: http://localhost:12003/metrics"
	@echo "  - TunnelServer Health: http://localhost:12003/health/live"
	@echo "  - ProxyEntry HTTP: http://localhost:12000"
	@echo "  - ProxyEntry Uplink: :12001"
	@echo "  - Grafana: http://localhost:3001"
	@echo "  - Prometheus: http://localhost:9091"
	@echo "  - OpenSearch: http://localhost:9201"
	@echo "  - OpenSearch Dashboards: http://localhost:5602"
	@echo ""
	@echo "🔧 Next steps:"
	@echo "  1. Configure Nginx reverse proxy (see nginx/tunnel2.conf)"
	@echo "  2. Setup DNS: *.tunnel2.xtunnel.ru → your_server_ip"
	@echo "  3. Monitor health: make health"
	@echo ""
	@echo "📚 Documentation:"
	@echo "  - PHASE6_PRODUCTION_DEPLOYMENT.md"
	@echo ""
