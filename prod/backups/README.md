# Сервисы бэкапирования PostgreSQL - Production

## Обзор

Автоматизированная система бэкапирования PostgreSQL с загрузкой в Yandex Object Storage (S3) для production инфраструктуры Tunnel2.

## Архитектура

1. **postgres_backup** - Сервис посхедельного бэкапирования баз данных
   - Создает отдельные pg_dump файлы для каждой из 28 production баз данных
   - Запускается ежедневно в 00:00 UTC
   - Retention: 7 дней, 4 недели, 0 месяцев

2. **rclone_s3_upload** - Сервис загрузки в S3
   - Синхронизирует бэкапы в Yandex Object Storage каждые 24 часа
   - Удаляет файлы старше 30 дней из облачного хранилища
   - Использует протокол S3 (не WebDAV - в 166 раз быстрее!)

## Файлы конфигурации

### Переменные окружения (не секретные)
**Файл:** `tunnel2-deploy/prod/env/backups.env`

Содержит всю несекретную конфигурацию:
- Настройки подключения к PostgreSQL (хост, пользователь)
- Список 28 баз данных для бэкапирования
- Расписание и политика хранения бэкапов
- Endpoint и имя бакета Yandex Object Storage

### Учетные данные (секретные)
**Файл:** `.env.backups.secret` (в корне проекта)

**ВНИМАНИЕ:** Этот файл исключен из git и содержит секретные учетные данные!

Содержит:
- `POSTGRES_BACKUP_PASSWORD` - Пароль пользователя backup_user PostgreSQL
- `YC_ACCESS_KEY_ID` - Yandex Cloud S3 Access Key ID
- `YC_SECRET_ACCESS_KEY` - Yandex Cloud S3 Secret Access Key

## Production деплой

### Предварительные требования

1. Убедитесь что `.env.backups.secret` существует в корне проекта с правильными учетными данными
2. Пользователь PostgreSQL для бэкапов должен иметь разрешения:
   ```sql
   GRANT pg_read_all_data TO backup_user;
   ALTER USER backup_user WITH REPLICATION;
   ```

### Запуск сервисов бэкапирования

```bash
# Запуск всей инфраструктуры включая сервисы бэкапов
cd tunnel2-deploy/prod
docker compose -f infrastructure.docker-compose.yml up -d

# Запуск только сервисов бэкапирования
docker compose -f infrastructure.docker-compose.yml up -d postgres_backup rclone_s3_upload
```

### Мониторинг

```bash
# Логи сервиса бэкапирования
docker logs tunnel2_postgres_backup -f

# Логи сервиса загрузки
docker logs tunnel2_rclone_s3_upload -f

# Проверка файлов бэкапа на диске
ls -lah tunnel2-deploy/prod/backups/postgres/

# Проверка загрузки в Yandex Object Storage
# Доступ через консоль Yandex Cloud: https://console.cloud.yandex.ru/
# Бакет: xtunnel-backups
```

### Ручной запуск бэкапа

```bash
# Запустить немедленный бэкап (отправить SIGUSR1)
docker exec tunnel2_postgres_backup sh -c 'kill -USR1 1'

# Запустить немедленную загрузку
docker restart tunnel2_rclone_s3_upload
```

## Список баз данных

Система бэкапирует 28 production баз данных в режиме per-database:

**Базы данных ChefBot (9):**
- ChefBot-4a0243ecea614a48a9c4a73b2499416e
- ChefBot-4de1ebb65c074ccaa5526fe0cccaf06b
- ChefBot-646e5a6c41ac4f5886a2305ce98e0ac1
- ChefBot-6e94dc757ef94d3f90fa57add8bbcf65
- ChefBot-73b3d2c746664746a9b3ef8a67d605d8
- ChefBot-ac1457931ae94dd7be84ce203bd28287
- ChefBot-adc01aa637294e6c92c60034701ba694
- ChefBot-bdc521d4248a4fe18516b5cdf463fda1
- ChefBot-d0c5051cf4cd403da8db13e91e2bb50b

**Базы данных ChefBotChatBot (9):**
- ChefBotChatBot-4a0243ecea614a48a9c4a73b2499416e
- ChefBotChatBot-4de1ebb65c074ccaa5526fe0cccaf06b
- ChefBotChatBot-646e5a6c41ac4f5886a2305ce98e0ac1
- ChefBotChatBot-6e94dc757ef94d3f90fa57add8bbcf65
- ChefBotChatBot-73b3d2c746664746a9b3ef8a67d605d8
- ChefBotChatBot-ac1457931ae94dd7be84ce203bd28287
- ChefBotChatBot-adc01aa637294e6c92c60034701ba694
- ChefBotChatBot-bdc521d4248a4fe18516b5cdf463fda1
- ChefBotChatBot-d0c5051cf4cd403da8db13e91e2bb50b

**Остальные базы данных (10):**
- ChefBotVendors
- Tunnel
- TunnelApi
- TunnelApiHangfire
- keycloak
- keycloakchefbot
- keycloakchefbotru
- postgres
- tunnel2

## Производительность

### Сравнение WebDAV vs S3

**Старая настройка WebDAV (Yandex.Disk):**
- Начальная скорость: 9 MB/s
- Throttled скорость: 40 KB/s (сильный throttling после ~70 секунд)
- Время загрузки 47 MB: ~20 минут

**Текущая настройка S3 (Yandex Object Storage):**
- Стабильная скорость: 7-8 MB/s (без throttling)
- Время загрузки 202 MB: ~26 секунд
- **В 166 раз быстрее throttled WebDAV!**

## Политика хранения

### Локальные бэкапы (на сервере)
- Ежедневные: последние 7 дней
- Еженедельные: последние 4 недели
- Ежемесячные: 0 (отключено)

### Облачные бэкапы (Yandex Object Storage)
- Файлы старше 30 дней автоматически удаляются

## Безопасность

- Учетные данные PostgreSQL используют сильный случайно сгенерированный пароль
- Учетные данные S3 используют Yandex Cloud IAM ключи доступа
- Файлы бэкапа хранятся с приватным ACL (не публичные)
- Файл с учетными данными исключен из git
- Все секреты загружаются из файла `.env.backups.secret`
