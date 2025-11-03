# OpenSearch Logging для Tunnel2

Централизованная система логирования на базе OpenSearch + Fluent Bit для всех сервисов tunnel2.

## Архитектура

```
┌──────────────────────────────────────────────────────────┐
│  Docker Containers (DNS, TunnelServer, ProxyEntry, etc)  │
└────────────────────────┬─────────────────────────────────┘
                         │ logs to stdout/stderr
                         ▼
                  ┌──────────────┐
                  │  Fluent Bit  │ ← Собирает логи из Docker
                  └──────┬───────┘
                         │ парсит JSON, добавляет метаданные
                         ▼
                  ┌──────────────┐
                  │  OpenSearch  │ ← Хранит и индексирует логи
                  └──────┬───────┘
                         │
                         ▼
            ┌────────────────────────┐
            │ OpenSearch Dashboards  │ ← UI для поиска и визуализации
            └────────────────────────┘
```

## Компоненты

### 1. OpenSearch (порт 9200)
- Хранилище логов с полнотекстовым поиском
- REST API для запросов
- Индекс: `tunnel2-logs-YYYY.MM.DD`

### 2. OpenSearch Dashboards (порт 5601)
- Web UI для просмотра логов
- Визуализация и дашборды
- Доступ: http://localhost:5601
- Логин: admin / Admin123!

### 3. Fluent Bit
- Легковесный сборщик логов
- Собирает логи из Docker контейнеров
- Парсит .NET JSON логи
- Добавляет метаданные (container name, labels)

## Быстрый старт

### 1. Запуск инфраструктуры с логированием

```bash
cd tunnel2-deploy/dev

# Запустить всю инфраструктуру (включая логирование)
docker compose -f docker-compose-infrastructure.yml up -d

# Проверить статус
docker compose -f docker-compose-infrastructure.yml ps

# Логи Fluent Bit (чтобы убедиться, что работает)
docker logs tunnel2_fluentbit
```

### 2. Доступ к OpenSearch Dashboards

1. Открыть http://localhost:5601
2. **Аутентификация отключена** (dev environment - security plugin disabled)
3. Первый запуск: создать Index Pattern
   - Go to: Management → Stack Management → Index Patterns
   - Create index pattern: `tunnel2-logs-*`
   - Time field: `@timestamp`
   - Save

4. Просмотр логов:
   - Go to: Discover
   - Выбрать index pattern `tunnel2-logs-*`
   - Фильтровать по сервисам, уровням логов, и т.д.

## Примеры поиска

### Поиск по сервису

```
# Все логи DNS Server
container_name: "tunnel2_dns_server"

# Все логи DNS Forwarder
container_name: "tunnel2_dns_forwarder"
```

### Поиск по уровню логов

```
# Только ошибки
log_level: "Error" OR log: "*fail*" OR log: "*error*"

# Warning и выше
log_level: ("Warning" OR "Error" OR "Critical")
```

### Поиск по SessionId

```
# Все события для конкретной сессии
log: "a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d"
```

### Поиск health check событий

```
# Health check queries
log: "health.check" OR log: "Health check"

# Health check failures
log: "Health check failed" OR log: "SERVFAIL"
```

### Поиск DNS queries

```
# Все DNS запросы
log: "DNS query"

# NXDOMAIN ответы
log: "NXDOMAIN" OR log: "NameError"

# Cache hits/misses
log: "Cache HIT" OR log: "Cache MISS"
```

### Поиск rate limiting

```
# Rate limit exceeded
log: "Rate limit exceeded"
```

## Полезные фильтры в Dashboards

### По времени
- Last 15 minutes
- Last 1 hour
- Last 24 hours
- Custom range

### По контейнеру
```
container_name: "tunnel2_dns_server"
container_name: "tunnel2_dns_forwarder"
container_name: "tunnel2_postgres"
container_name: "tunnel2_opensearch"
```

### По уровню важности
- ERROR: `log: "*error*"`
- WARNING: `log: "*warn*"`
- INFO: `log: "*info*"`

## REST API примеры

### Поиск через curl

```bash
# Последние 10 логов
curl -X GET "http://localhost:9200/tunnel2-logs-*/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 10,
    "sort": [{"@timestamp": "desc"}]
  }'

# Поиск ошибок за последний час
curl -X GET "http://localhost:9200/tunnel2-logs-*/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "bool": {
        "must": [
          {"match": {"log": "error"}},
          {"range": {"@timestamp": {"gte": "now-1h"}}}
        ]
      }
    }
  }'

# Статистика по контейнерам
curl -X GET "http://localhost:9200/tunnel2-logs-*/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "size": 0,
    "aggs": {
      "by_container": {
        "terms": {"field": "container_name.keyword"}
      }
    }
  }'
```

## Создание дашбордов

### 1. DNS Activity Dashboard

**Визуализации:**
- Line chart: DNS queries per minute
- Pie chart: Query types (A, AAAA, TXT, etc.)
- Table: Top queried domains
- Counter: Cache hit rate
- Counter: Rate limit violations

### 2. Health Check Dashboard

**Визуализации:**
- Line chart: Health check success/failure over time
- Counter: Current health status
- Table: Recent health check failures with reasons
- Pie chart: Health check by service

### 3. Errors Dashboard

**Визуализации:**
- Line chart: Errors per minute by service
- Table: Recent errors with stack traces
- Heatmap: Error patterns over time
- Top errors by type

## Конфигурация

### Увеличение retention (хранение логов)

По умолчанию логи хранятся бесконечно. Для ограничения:

```bash
# Создать Index Lifecycle Policy
curl -X PUT "http://localhost:9200/_plugins/_ism/policies/tunnel2-logs-policy" \
  -H 'Content-Type: application/json' \
  -d '{
    "policy": {
      "description": "Delete logs older than 30 days",
      "default_state": "hot",
      "states": [
        {
          "name": "hot",
          "actions": [],
          "transitions": [{
            "state_name": "delete",
            "conditions": {"min_index_age": "30d"}
          }]
        },
        {
          "name": "delete",
          "actions": [{"delete": {}}],
          "transitions": []
        }
      ]
    }
  }'
```

### Настройка алертов

OpenSearch поддерживает алерты на определенные условия:
- Количество ошибок превышает порог
- Health check failures
- Rate limiting срабатывает слишком часто
- Сервис не отправляет логи (down)

## Troubleshooting

### OpenSearch не стартует

```bash
# Проверить логи
docker logs tunnel2_opensearch

# Увеличить memory limits если нужно
# В docker-compose-logging.yml изменить:
OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g
```

### Fluent Bit не отправляет логи

```bash
# Проверить логи Fluent Bit
docker logs tunnel2_fluentbit

# Проверить подключение к OpenSearch
docker exec tunnel2_fluentbit curl -k https://opensearch:9200 -u admin:Admin123!
```

### Логи не появляются в Dashboards

```bash
# Проверить, что индекс создан
curl http://localhost:9200/_cat/indices?v

# Проверить количество документов
curl http://localhost:9200/tunnel2-logs-*/_count?pretty

# Пересоздать Index Pattern в Dashboards
```

### Очистка данных для тестов

```bash
# Удалить все логи
curl -X DELETE http://localhost:9200/tunnel2-logs-*

# Остановить и удалить volumes
docker compose -f docker-compose-infrastructure.yml down -v
```

## Production рекомендации

1. **Security:**
   - Изменить пароль admin
   - Настроить TLS сертификаты
   - Ограничить доступ через firewall

2. **Performance:**
   - Увеличить heap size: `-Xms2g -Xmx2g`
   - Настроить shards и replicas
   - Index lifecycle management (ILM)

3. **Backup:**
   - Настроить snapshot repository
   - Регулярные бэкапы индексов

4. **Monitoring:**
   - Мониторинг самого OpenSearch
   - Алерты на disk usage
   - Алерты на health status

## Полезные ссылки

- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [OpenSearch Query DSL](https://opensearch.org/docs/latest/query-dsl/)
