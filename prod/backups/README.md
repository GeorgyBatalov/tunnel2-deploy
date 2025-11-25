# PostgreSQL Backup System

Автоматическая система резервного копирования PostgreSQL с загрузкой на Яндекс.Диск.

## Быстрый старт

```bash
# 1. Создать .env из примера
cp .env.example .env
# Отредактировать .env: заполнить пароли

# 2. Создать backup_user в PostgreSQL
./scripts/setup_backup_user.sh

# 3. Настроить rclone для Яндекс.Диска
./scripts/setup_rclone.sh

# 4. Запустить контейнеры
docker compose -f docker-compose-backup.yml up -d

# 5. Проверить логи
docker compose -f docker-compose-backup.yml logs -f
```

## Архитектура

```
PostgreSQL (tunnel2)
    ↓ (backup_user: read-only)
postgres_backup container
    ↓ (pg_dump @ 00:00 UTC daily)
./postgres/ (local storage)
    ├── daily/   (7 days retention)
    ├── weekly/  (4 weeks retention)
    └── last/    (latest backup)
    ↓ (rclone sync every 24h)
Yandex.Disk
    └── xtunnel-backups/ (30 days retention)
```

## Структура файлов

```
backups/
├── .env.example           # Пример конфигурации
├── .env                   # Ваша конфигурация (не коммитится)
├── README.md
├── docker-compose-backup.yml
├── postgres/              # Локальные бэкапы (создается автоматически)
├── rclone/                # rclone конфиг (создается автоматически)
└── scripts/
    ├── create_backup_user.sql
    ├── setup_backup_user.sh
    ├── setup_rclone.sh
    ├── rclone_sync.sh
    └── test_restore.sh
```

## Требования

1. Docker и Docker Compose
2. Запущенный PostgreSQL контейнер с именем `postgres`
3. Сеть `tunnel2-network` (должна существовать)
4. Пароль приложения Яндекс.Диска: https://id.yandex.ru/security/app-passwords

## Детальная инструкция

### 1. Подготовка

```bash
# Сгенерировать пароль для backup_user
openssl rand -base64 32

# Получить пароль приложения Яндекс:
# https://id.yandex.ru/security/app-passwords
```

### 2. Настройка .env

```bash
cp .env.example .env
nano .env
```

Заполнить:
- `POSTGRES_BACKUP_PASSWORD` - сгенерированный пароль
- `YANDEX_USERNAME` - ваш Яндекс логин
- `YANDEX_APP_PASSWORD` - пароль приложения

### 3. Создание backup_user

```bash
./scripts/setup_backup_user.sh
```

Скрипт:
- Создаст пользователя `backup_user` с read-only правами
- Проверит что SELECT работает
- Проверит что INSERT запрещен

### 4. Настройка rclone

```bash
./scripts/setup_rclone.sh
```

Скрипт:
- Создаст `rclone.conf` для WebDAV подключения
- Проверит подключение к Яндекс.Диску
- Создаст папку `xtunnel-backups`

### 5. Запуск

**Через docker compose (рекомендуется):**

```bash
docker compose -f docker-compose-backup.yml up -d
```

**Вручную (альтернатива):**

```bash
source .env

# Backup контейнер
docker run -d \
  --name tunnel2_postgres_backup \
  --restart unless-stopped \
  --network tunnel2-network \
  -e POSTGRES_HOST=postgres \
  -e POSTGRES_DB=tunnel2 \
  -e POSTGRES_USER=$POSTGRES_BACKUP_USER \
  -e POSTGRES_PASSWORD="$POSTGRES_BACKUP_PASSWORD" \
  -e SCHEDULE=@daily \
  -e BACKUP_KEEP_DAYS=7 \
  -e BACKUP_KEEP_WEEKS=4 \
  -e BACKUP_KEEP_MONTHS=0 \
  -e POSTGRES_EXTRA_OPTS="--format=custom --compress=9 --no-owner --no-acl" \
  -v $(pwd)/postgres:/backups \
  prodrigestivill/postgres-backup-local:16

# rclone контейнер
docker run -d \
  --name tunnel2_rclone_upload \
  --restart unless-stopped \
  --network tunnel2-network \
  -v $(pwd)/postgres:/data:ro \
  -v $(pwd)/rclone:/config/rclone:ro \
  -v $(pwd)/scripts/rclone_sync.sh:/rclone_sync.sh:ro \
  --entrypoint=/bin/sh \
  rclone/rclone:1.65 /rclone_sync.sh
```

## Проверка

### Проверка статуса

```bash
docker compose -f docker-compose-backup.yml ps
```

### Проверка логов

```bash
# Все логи
docker compose -f docker-compose-backup.yml logs -f

# Только backup
docker logs tunnel2_postgres_backup

# Только rclone
docker logs tunnel2_rclone_upload
```

### Ручной запуск backup

```bash
docker exec tunnel2_postgres_backup /backup.sh
```

### Проверка файлов

```bash
# Локально
ls -lh postgres/daily/
ls -lh postgres/last/

# На Яндекс.Диске
docker run --rm -v $(pwd)/rclone:/config/rclone \
  rclone/rclone:1.65 size yandex:xtunnel-backups
```

### Тестовое восстановление

```bash
./scripts/test_restore.sh
```

## Расписание

- **Backup:** Каждый день в 00:00 UTC
- **Sync to Yandex:** Каждые 24 часа (после первого запуска)
- **Cleanup:** При каждом sync (удаление файлов >30 дней)

## Retention Policy

### Локально (postgres/)
- Daily: 7 дней
- Weekly: 4 недели
- Monthly: 0

### Яндекс.Диск
- Все файлы: 30 дней
- Автоматическая очистка при каждом sync

## Восстановление

### Тестовое (безопасно)

```bash
./scripts/test_restore.sh
```

### Production (ОПАСНО!)

**⚠️ Приведет к downtime сервиса!**

```bash
# 1. Остановить сервисы
docker stop tunnel2_server tunnel2_entry

# 2. Найти нужный backup
ls -lh postgres/daily/

# 3. Восстановить
docker exec postgres dropdb -U tunnel tunnel2
docker exec postgres createdb -U tunnel tunnel2
docker exec postgres pg_restore -U tunnel -d tunnel2 \
  /path/to/backup.sql.gz

# 4. Пересоздать backup_user
./scripts/setup_backup_user.sh

# 5. Запустить сервисы
docker start tunnel2_server tunnel2_entry
```

## Управление

### Остановка

```bash
docker compose -f docker-compose-backup.yml down
```

### Перезапуск

```bash
docker compose -f docker-compose-backup.yml restart
```

### Обновление образов

```bash
docker compose -f docker-compose-backup.yml pull
docker compose -f docker-compose-backup.yml up -d
```

## Troubleshooting

### Backup контейнер unhealthy

```bash
# Проверить логи
docker logs tunnel2_postgres_backup

# Проверить файлы
ls -la postgres/

# Проверить подключение к БД
docker exec tunnel2_postgres_backup \
  psql -h postgres -U backup_user -d tunnel2 -c "SELECT 1;"
```

### rclone не может загрузить на Яндекс

```bash
# Проверить rclone config
docker run --rm -v $(pwd)/rclone:/config/rclone \
  rclone/rclone:1.65 config show

# Протестировать подключение
docker run --rm -v $(pwd)/rclone:/config/rclone \
  rclone/rclone:1.65 lsd yandex:

# Пересоздать конфиг
./scripts/setup_rclone.sh
```

### Файл не восстанавливается (not in gzip format)

Backup в **PostgreSQL custom format**, не в plain gzip!

Используйте `pg_restore`, а не `gunzip`:

```bash
pg_restore -U tunnel -d tunnel2 backup.sql.gz
```

## Безопасность

- ✅ backup_user имеет только SELECT права
- ✅ rclone.conf с правами 600
- ✅ Пароли в .env (не в git)
- ✅ Яндекс.Диск через WebDAV (HTTPS)
- ✅ Volumes в read-only режиме где возможно

## Полная документация

См. `docs/phases/phase-6-backup-production-guide.md`

## Поддержка

В случае проблем:
1. Проверьте логи контейнеров
2. Запустите `./scripts/test_restore.sh`
3. Проверьте что .env заполнен корректно
4. Убедитесь что сеть `tunnel2-network` существует
