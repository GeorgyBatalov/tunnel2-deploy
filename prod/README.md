# Tunnel2 Production Deployment

Этот каталог содержит production конфигурацию для развертывания Tunnel2 на сервере `georgy@78.29.43.89`.

## Структура

```
prod/
├── infrastructure.docker-compose.yml  # Инфраструктура (Redis, Vault, OpenSearch, Prometheus)
├── services.docker-compose.yml        # Сервисы (tunnel2-server, tunnel2-proxy-entry)
├── Makefile                           # Команды для деплоя
├── .env.template                      # Шаблон с секретами
├── .env                               # Реальные секреты (НЕ коммитить!)
├── env/                               # Environment файлы для сервисов
│   ├── tunnel_server.env
│   └── tunnel_entry.env
├── nginx/                             # Nginx конфиги
│   └── tunnel2.conf
├── vault/                             # Vault конфиги
├── prometheus/                        # Prometheus конфиги + alert rules
├── grafana/                           # Grafana dashboards
└── fluentbit/                         # Fluent Bit конфиги
```

## Быстрый старт

### 1. Первичная настройка (один раз)

```bash
# На сервере production
cd /path/to/tunnel2-deploy/prod

# Создать .env файл
make init

# Отредактировать .env и заполнить CHANGE_ME значения
nano .env
```

**Важно:** В `.env` нужно установить:
- `POSTGRES_PASSWORD` - сильный пароль для PostgreSQL
- `RABBITMQ_PASSWORD` - сильный пароль для RabbitMQ
- `GRAFANA_ADMIN_PASSWORD` - пароль для админа Grafana

### 2. Деплой (автоматический)

```bash
# Полный деплой: pull + build + up + wait
make deploy
```

Эта команда:
1. Стянет последний код из GitHub
2. Соберет Docker images
3. Запустит инфраструктуру и сервисы
4. Подождет, пока все сервисы станут healthy
5. Покажет endpoints и следующие шаги

### 3. Инициализация Vault (один раз)

После первого деплоя нужно инициализировать Vault:

```bash
# Инициализировать Vault
make vault-init

# ВАЖНО: Сохранить вывод (5 unseal keys + root token) в надежном месте!

# Unseal Vault (интерактивно)
make vault-unseal

# Обновить .env файл с VAULT_ROOT_TOKEN
nano .env

# Перезапустить сервисы
make restart
```

### 4. Настройка Nginx (один раз)

```bash
# На сервере production
# 1. Подключить tunnel_proxy к tunnel2-network
docker network connect tunnel2-network tunnel_proxy

# 2. Скопировать конфиг в tunnel_proxy
docker cp /path/to/tunnel2-deploy/prod/nginx/tunnel2.conf tunnel_proxy:/etc/nginx/conf.d/

# 3. Проверить синтаксис
docker exec tunnel_proxy nginx -t

# 4. Перезагрузить Nginx
docker exec tunnel_proxy nginx -s reload
```

### 5. Настройка DNS (один раз)

Добавить wildcard DNS запись:
```
*.tunnel2.xtunnel.ru  A  78.29.43.89
```

## Команды Makefile

### Управление сервисами

```bash
make up              # Запустить все сервисы
make down            # Остановить все сервисы
make restart         # Перезапустить все сервисы

make infra-up        # Запустить только инфраструктуру
make infra-down      # Остановить только инфраструктуру
make services-up     # Запустить только tunnel2 сервисы
make services-down   # Остановить только tunnel2 сервисы
```

### Мониторинг

```bash
make ps              # Показать запущенные контейнеры
make logs            # Показать логи (Ctrl+C для выхода)
make health          # Проверить здоровье всех сервисов
make wait            # Подождать, пока все сервисы станут healthy
```

### Обновление

```bash
make pull            # Стянуть последний код из GitHub
make build           # Пересобрать Docker images
make deploy          # Полный деплой (pull + build + up + wait)
```

### Vault

```bash
make vault-init      # Инициализировать Vault (только один раз!)
make vault-unseal    # Unseal Vault (интерактивно)
make vault-status    # Проверить статус Vault
```

### Очистка

```bash
make clean           # Удалить все контейнеры и volumes (ОПАСНО!)
```

## Endpoints

После успешного деплоя сервисы доступны по следующим адресам:

### Tunnel2 Services
- **TunnelServer Control Plane:** `:12002` (TLS)
- **TunnelServer HTTP API:** `http://localhost:12003`
- **TunnelServer Metrics:** `http://localhost:12003/metrics`
- **TunnelServer Health:** `http://localhost:12003/health/live`
- **ProxyEntry HTTP:** `http://localhost:12000` (за Nginx)
- **ProxyEntry Uplink:** `:12001`
- **TCP Public Ports:** `40000-49999` (10000 портов)

### Observability
- **Grafana:** `http://localhost:3001` (админ: см. `.env`)
- **Prometheus:** `http://localhost:9091`
- **OpenSearch:** `http://localhost:9201`
- **OpenSearch Dashboards:** `http://localhost:5602`

### Infrastructure
- **Vault:** `http://localhost:8201`
- **Redis:** `localhost:6380`
- **RabbitMQ Management:** `http://localhost:15673`
- **PostgreSQL:** `localhost:5433`

## Проверка здоровья

```bash
# Быстрая проверка
make health

# Детальная проверка tunnel2_server
curl http://localhost:12003/health/live
curl http://localhost:12003/health/ready

# Проверка метрик
curl http://localhost:12003/metrics | grep tunnels_active_total
```

## Логи

```bash
# Все сервисы
make logs

# Только инфраструктура
make logs-infra

# Только tunnel2 сервисы
make logs-services

# Конкретный сервис
docker logs -f tunnel2_server
docker logs -f tunnel2_entry
docker logs -f tunnel2_prometheus
```

## Откат (Rollback)

Если что-то пошло не так:

```bash
# Остановить tunnel2 сервисы (инфраструктура продолжит работать)
make services-down

# Или остановить всё
make down

# Старый tunnel v1 продолжит работать на портах 9090, 9092
```

## Безопасность

### Что НЕ коммитить в git:
- `.env` - реальные пароли и токены
- `vault/data/` - данные Vault
- `grafana/*.db` - база Grafana
- Любые `.log` файлы

### Vault Unseal Keys
- Сохранить 5 unseal keys в **надежном месте** (KeePass, 1Password, etc.)
- Для unseal нужны любые 3 из 5 ключей
- Root token сохранить в `.env` файл

### Пароли
- Используй сильные пароли (минимум 16 символов)
- Не используй одинаковые пароли для разных сервисов

## Мониторинг

### Grafana Dashboards
1. Открыть `http://localhost:3001`
2. Логин: см. `.env` (`GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD`)
3. Доступные dashboards:
   - **Session Overview** - активные сессии, создание/закрытие сессий
   - **Quota Limits** - квоты, denials, usage
   - **HTTP & TCP Traffic** - трафик, request rate, latency

### Prometheus Alerts
Алерты настроены в `prometheus/rules/tunnel2-alerts.yml`:
- `Tunnel2ServerDown` - сервер недоступен >1 мин
- `HighQuotaDenialRate` - высокий denial rate
- `HighSessionCloseRate` - аномальное закрытие сессий
- `RedisConnectionFailed` - проблемы с Redis
- И другие...

## Troubleshooting

### Сервис не стартует
```bash
# Проверить логи
docker logs tunnel2_server
docker logs tunnel2_entry

# Проверить health checks
make health

# Проверить, что инфраструктура healthy
docker ps --filter "name=tunnel2_"
```

### Vault sealed
```bash
# Проверить статус
make vault-status

# Unseal
make vault-unseal
```

### Nginx не маршрутизирует на tunnel2
```bash
# Проверить, что tunnel_proxy подключен к tunnel2-network
docker inspect tunnel_proxy | grep tunnel2-network

# Если нет, подключить
docker network connect tunnel2-network tunnel_proxy

# Проверить конфиг Nginx
docker exec tunnel_proxy nginx -t

# Перезагрузить Nginx
docker exec tunnel_proxy nginx -s reload
```

### PostgreSQL connection failed
```bash
# Проверить PostgreSQL
docker exec tunnel2_postgres pg_isready -U tunnel2_user

# Проверить пароль в .env
cat .env | grep POSTGRES_PASSWORD

# Проверить env файл tunnel_server
cat env/tunnel_server.env | grep ConnectionStrings__PostgreSQL
```

## Полная документация

Подробная информация в:
- [../../PHASE6_PRODUCTION_DEPLOYMENT.md](../../PHASE6_PRODUCTION_DEPLOYMENT.md) - Production Deployment Guide
- [../../ROADMAP.md](../../ROADMAP.md) - Phase 6 status

## Контакты

Если возникли проблемы, проверь:
1. Логи сервисов: `make logs`
2. Health checks: `make health`
3. Vault status: `make vault-status`
4. Документацию: `PHASE6_PRODUCTION_DEPLOYMENT.md`
