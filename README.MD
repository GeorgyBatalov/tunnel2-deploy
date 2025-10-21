# Tunnel2 Deploy

## Purpose
Содержит скрипты и конфигурации для деплоя всех компонентов Tunnel2:
- локально через docker-compose,
- в будущем — Dev, Staging, Production окружения.

## Structure
- `dev/` — конфигурации для локальной разработки
  - `docker-compose-infrastructure.yml` — инфраструктурные сервисы (Vault, Redis, RabbitMQ)
  - `docker-compose.yml` — приложения Tunnel2 и тестовые бэкенды
  - `env/` — переменные окружения для dev
  - `vault/` — конфигурация Vault для dev
- `prod/` — конфигурации для production окружения (пока пустая)
- `scripts/` — shell-скрипты для сборки, рестарта, деплоя

## Build & Run Locally (Development)

### Первый запуск (или после полной остановки)

```bash
# 1. Запустить инфраструктурные сервисы (один раз)
docker compose -f dev/docker-compose-infrastructure.yml up -d

# 2. Инициализировать и распечатать Vault (один раз после первого запуска)
# ... выполните vault operator init и vault operator unseal ...

# 3. Запустить приложения Tunnel2
docker compose -f dev/docker-compose.yml up -d --build
```

### Обычная работа

```bash
# Пересобрать и перезапустить только приложения (Vault не трогается!)
docker compose -f dev/docker-compose.yml up -d --build

# Пересобрать только конкретный сервис
docker compose -f dev/docker-compose.yml up -d --build tunnel_server

# Остановить приложения (инфраструктура продолжает работать)
docker compose -f dev/docker-compose.yml down

# Полная остановка всего (включая Vault - потребуется unseal при следующем запуске)
docker compose -f dev/docker-compose.yml down
docker compose -f dev/docker-compose-infrastructure.yml down
```

**Преимущества такого подхода:**
- Vault, Redis, RabbitMQ не перезапускаются при пересборке приложений
- Vault остаётся распечатанным (unsealed) между пересборками
- Быстрее пересборка - только изменённые сервисы
- Чёткое разделение dev/prod окружений

## Configuration

### Environment Variables

Конфигурация сервисов управляется через файлы в директории `env/`:

- `tunnel_server.env` - переменные для TunnelServer (Control Plane)
- `tunnel_entry.env` - переменные для ProxyEntry (Data Plane)

**Важно:** Реальные секреты (Vault tokens, RSA ключи) хранятся в Vault и НЕ должны коммититься в репозиторий!

### Vault Integration

Все сервисы используют HashiCorp Vault для получения секретных данных:

```env
Vault__Address=http://vault:8200
Vault__Token=REPLACE_WITH_YOUR_VAULT_TOKEN
```

**Перед запуском:** Замените плейсхолдеры на реальные значения Vault токена.

### Dev Features

#### AllowDevSessionId

Для локального тестирования и интеграционных тестов TunnelServer поддерживает кастомные SessionId:

```env
# tunnel_server.env
TunnelServer__AllowDevSessionId=true
```

**Что это даёт:**
- Клиент может указать фиксированный SessionId через параметр `--dev-session-id`
- URL туннеля становится предсказуемым: `http://{session-id}-e1.tunnel.local:12000`
- Упрощает разработку и тестирование

**Безопасность:**
- Этот флаг должен быть `true` только в dev/test окружениях
- В Production среде установите `AllowDevSessionId=false` или не указывайте эту переменную

**Пример использования:**
```bash
# Запуск клиента с фиксированным SessionId
dotnet run --project tunnel2-client/src/Tunnel.ClientApp -- \
  --dev-session-id=a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d \
  --backend-host=localhost \
  --backend-port=12005

# Теперь всегда доступно по адресу:
# http://a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d-e1.tunnel.local:12000
```


## ⚙️ Port Convention

Для единообразия при разработке и отладке используется следующая схема портов:

| Environment | Purpose | Port Range | Example |
|--------------|----------|-------------|----------|
| **Docker** | Контейнеры, запущенные через `tunnel2-deploy/docker-compose-localhost.yml` | `12000–12099` | `12000` – ProxyEntry (HTTP)<br>`12001` – ProxyEntry (uplink)<br>`12002` – TunnelServer |
| **Localhost (Debug)** | Локально запущенные сервисы в IDE (например, Rider, VSCode) | `13000–13099` | `13000` – ProxyEntry (HTTP)<br>`13001` – ProxyEntry (uplink)<br>`13002` – TunnelServer |
| **External Services** | Сторонние сервисы (Vault, Redis, RabbitMQ, httpbin и т. д.) | их “родные” порты | `8200` – Vault<br>`6379` – Redis<br>`5672` – RabbitMQ<br>`8080` – TestBackend |

### Правило:  
- Порты `12xxx` зарезервированы для контейнеров Docker (production/dev/test окружения).  
- Порты `13xxx` используются только при локальной отладке, чтобы избежать конфликтов и можно было легко различать, где запущен сервис.  
- Сторонние сервисы по возможности используют свои стандартные (родные) порты.