# Tunnel2 Deploy

## Purpose
Содержит скрипты и конфигурации для деплоя всех компонентов Tunnel2:
- локально через docker-compose,
- в будущем — Dev, Staging, Production окружения.

## Structure
- `docker-compose-localhost.yml` — локальное окружение.
- `env/` — шаблоны переменных окружения (секреты пустые).
- `scripts/` — shell-скрипты для сборки, рестарта, деплоя.
- `vault/` — конфиги и bootstrap для HashiCorp Vault.

## Build & Run Locally
`docker compose -f docker-compose-localhost.yml up --build`


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