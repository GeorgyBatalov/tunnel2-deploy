# PostgreSQL Backup - Quick Start Guide

**Цель:** Настроить автоматическое резервное копирование PostgreSQL с отправкой на Яндекс.Диск за 15 минут.

---

## ⚡ Быстрый старт (3 команды)

```bash
cd /opt/xtunnel/tunnel2-deploy/prod

# 1. Инициализация всей системы backup (интерактивно)
make backup-init

# 2. Проверка что backup работает
make backup-now
make backup-status

# 3. Тест восстановления (КРИТИЧНО!)
make backup-test-restore
```

**Готово!** Теперь бэкапы создаются каждый день в 00:00 UTC и отправляются на Яндекс.Диск.

---

## 📋 Детальная инструкция

### Шаг 1: Подготовка

#### 1.1. Генерация пароля для backup_user

```bash
# Генерировать безопасный пароль
openssl rand -base64 32
```

Сохрани вывод в безопасном месте!

#### 1.2. Создание пароля приложения в Яндекс.Паспорте

1. Открой: https://id.yandex.ru/security/app-passwords
2. Нажми "Создать пароль приложения"
3. Название: `xtunnel-backup`
4. Скопируй сгенерированный пароль (он больше не будет показан!)

#### 1.3. Обновление .env

```bash
cd /opt/xtunnel/tunnel2-deploy/prod
nano .env
```

Добавь или обнови:

```bash
# PostgreSQL Backup Configuration
POSTGRES_BACKUP_USER=backup_user
POSTGRES_BACKUP_PASSWORD=<paste_generated_password_from_step_1.1>
BACKUP_SYNC_INTERVAL=86400      # 24 hours
BACKUP_RETENTION_DAYS=30        # 30 days on Yandex.Disk
```

Сохрани (Ctrl+O) и выйди (Ctrl+X).

---

### Шаг 2: Создание read-only пользователя

```bash
cd /opt/xtunnel/tunnel2-deploy/prod

# Автоматическая установка с проверками
make backup-setup
```

**Что происходит:**
- Создается пользователь `backup_user`
- Права: только `SELECT` (чтение)
- Проверяется что пользователь НЕ может писать
- Проверяется что `pg_dump` работает

**Ожидаемый вывод:**

```
✓ backup_user created successfully
✓ SELECT works
✓ CREATE TABLE denied (as expected)
✓ pg_dump works
All tests passed!
```

---

### Шаг 3: Настройка rclone для Яндекс.Диска

```bash
make backup-config-rclone
```

**Интерактивный диалог:**

```
n) New remote
name> yandex
Storage> yandex  (или номер, обычно 44)
client_id> (Enter - оставить пустым)
client_secret> (Enter - оставить пустым)
Yandex Application Password> PASTE_APP_PASSWORD_FROM_STEP_1.2
Edit advanced config? n
y) Yes this is OK
q) Quit config
```

**Проверка подключения:**

```bash
make backup-test-rclone
```

Должно показать список директорий на Яндекс.Диске (или пусто если диск пустой).

---

### Шаг 4: Запуск backup сервисов

```bash
make backup-up
```

**Что запускается:**
- `tunnel2_postgres_backup` - делает pg_dump каждый день в 00:00
- `tunnel2_rclone_upload` - отправляет бэкапы на Яндекс.Диск каждые 24 часа

**Проверка логов:**

```bash
make backup-logs
```

---

### Шаг 5: Тестирование

#### 5.1. Принудительный backup (не ждать до 00:00)

```bash
make backup-now
```

Подожди 10-30 секунд и проверь статус:

```bash
make backup-status
```

**Ожидаемый вывод:**

```
=== Local Backups ===
-rw-r--r-- 1 root root 35M Nov 24 15:30 tunnel2_2025-11-24_15-30-00.dump

=== Yandex.Disk Backups ===
35124567 tunnel2_2025-11-24_15-30-00.dump

=== Container Status ===
NAMES                      STATUS                  STATE
tunnel2_postgres_backup    Up 5 minutes (healthy)  running
tunnel2_rclone_upload      Up 5 minutes            running
```

#### 5.2. Тест восстановления (КРИТИЧНО!)

```bash
make backup-test-restore
```

**Что происходит:**
1. Создается временный PostgreSQL контейнер
2. Восстанавливается последний backup
3. Проверяется что таблицы на месте
4. Контейнер удаляется

**Ожидаемый вывод:**

```
Using backup: tunnel2_2025-11-24_15-30-00.dump
Size: 35M

Creating test PostgreSQL container...
Restoring backup...
✓ Tables restored successfully

Tables in restored database:
  public | users     | table | test
  public | licenses  | table | test

✅ Restore test completed!
Tables restored: 2
```

**Если restore прошел успешно → backup работает корректно!**

---

## 📊 Управление backup

### Посмотреть статус

```bash
make backup-status
```

### Посмотреть логи

```bash
make backup-logs
```

### Сделать backup сейчас

```bash
make backup-now
```

### Остановить backup сервисы

```bash
make backup-down
```

### Запустить backup сервисы

```bash
make backup-up
```

### Очистить старые локальные бэкапы (>7 дней)

```bash
make backup-clean
```

---

## 🔄 Восстановление в production

### Полное восстановление базы данных

```bash
cd /opt/xtunnel/tunnel2-deploy/prod

# 1. Остановить сервисы которые пишут в БД
docker compose -f services.docker-compose.yml down

# 2. Скачать нужный backup с Яндекс.Диска
docker run --rm \
  -v $(pwd)/rclone:/config/rclone \
  -v /tmp:/tmp \
  rclone/rclone:1.65 copy \
    yandex:xtunnel-backups/tunnel2_2025-11-20_00-00-00.dump \
    /tmp/

# 3. Дропнуть и пересоздать базу
docker exec tunnel2_postgres psql -U tunnel -c "DROP DATABASE tunnel2;"
docker exec tunnel2_postgres psql -U tunnel -c "CREATE DATABASE tunnel2;"

# 4. Восстановить из backup
docker exec -i tunnel2_postgres \
  pg_restore -U tunnel -d tunnel2 --verbose --no-owner --no-acl \
    < /tmp/tunnel2_2025-11-20_00-00-00.dump

# 5. Пересоздать backup_user
make backup-setup

# 6. Запустить сервисы
docker compose -f services.docker-compose.yml up -d
```

### Восстановление отдельной таблицы

```bash
# Список таблиц в backup
pg_restore -l /tmp/backup.dump | grep TABLE

# Восстановить только таблицу users
docker exec -i tunnel2_postgres \
  pg_restore -U tunnel -d tunnel2 --table=users \
    < /tmp/backup.dump
```

---

## 🛠 Troubleshooting

### Проблема: "POSTGRES_BACKUP_PASSWORD is not set"

**Решение:**

```bash
cd /opt/xtunnel/tunnel2-deploy/prod
nano .env

# Добавить:
POSTGRES_BACKUP_PASSWORD=<your_secure_password>
```

### Проблема: "backup_user cannot connect"

**Решение:**

```bash
# Проверить что пользователь создан
docker exec tunnel2_postgres psql -U tunnel -d tunnel2 -c "\du"

# Пересоздать
make backup-setup
```

### Проблема: "rclone: connection failed"

**Решение:**

```bash
# Проверить rclone config
docker run --rm \
  -v $(pwd)/rclone:/config/rclone \
  rclone/rclone:1.65 config show

# Пересоздать пароль приложения на Яндексе
# Обновить rclone config
make backup-config-rclone
```

### Проблема: "No backups on Yandex.Disk"

**Причина:** rclone еще не выполнил первую синхронизацию (по умолчанию раз в 24 часа)

**Решение:**

```bash
# Принудительная синхронизация
docker restart tunnel2_rclone_upload

# Проверить логи
docker logs -f tunnel2_rclone_upload
```

---

## 📈 Retention Policy

### Локальное хранилище

- **Daily backups:** 7 дней (хранятся последние 7 дней)
- **Weekly backups:** 4 недели (хранится последний backup каждой недели)
- **Monthly backups:** 0 (не храним)

**Управляется автоматически** контейнером `prodrigestivill/postgres-backup-local`.

### Яндекс.Диск

- **Retention:** 30 дней (по умолчанию)
- Файлы старше 30 дней удаляются автоматически

**Изменить retention:**

```bash
# В .env изменить
BACKUP_RETENTION_DAYS=60  # Хранить 60 дней

# Перезапустить rclone
docker compose -f infrastructure.docker-compose.yml restart rclone_upload
```

---

## ✅ Checklist для production

- [ ] Создан `backup_user` с read-only правами
- [ ] Проверено что `backup_user` НЕ может писать
- [ ] Настроен rclone с Яндекс.Диском
- [ ] Пароль backup_user добавлен в `.env`
- [ ] Запущены контейнеры `postgres_backup` и `rclone_upload`
- [ ] Выполнен ручной backup (`make backup-now`)
- [ ] Проверено наличие файлов локально
- [ ] Проверено наличие файлов на Яндекс.Диске
- [ ] **КРИТИЧНО:** Выполнен test restore (`make backup-test-restore`)
- [ ] Добавлен мониторинг (healthchecks работают)
- [ ] Задокументирован процесс восстановления

---

## 🔗 Полезные ссылки

- [Детальный план](../../docs/phases/phase-6-backup-implementation.md) - полная документация
- [Makefile команды](#управление-backup) - все доступные команды
- [Troubleshooting](#troubleshooting) - решение проблем

---

## 🚀 Дальнейшее развитие

После успешного внедрения backup:

1. **Еженедельное тестирование** - добавить cron job для автоматической проверки restore
2. **Prometheus метрики** - мониторинг времени и размера backups
3. **Alerting** - алерты если backup старше 25 часов
4. **Шифрование** - добавить `rclone crypt` для шифрования на Яндекс.Диске
5. **Second location** - репликация на второй сервис (S3, etc)

---

**Время настройки:** 15-20 минут
**Поддержка:** 15 минут в неделю (проверка логов + test restore)
**Версия:** 1.0
