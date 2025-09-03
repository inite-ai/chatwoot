# Решение конфликтов контейнеров Docker Compose

## Проблема
Два разных проекта (Chatwoot и Hi-Events) используют одинаковые имена контейнеров, что приводит к их взаимному удалению при запуске.

## Причина
Docker Compose генерирует имена контейнеров в формате `{project_name}_{service_name}_{instance}`. Если проекты не имеют уникальных имен, они перезаписывают контейнеры друг друга.

## Решения

### 1. Использование переменной COMPOSE_PROJECT_NAME (Рекомендуемо)

**Для Chatwoot** (в `/opt/projects/chatwoot/current/.env`):
```env
COMPOSE_PROJECT_NAME=chatwoot
```

**Для Hi-Events** (в `/opt/projects/hi-events/current/.env`):
```env
COMPOSE_PROJECT_NAME=hievents
```

### 2. Использование флага -p при запуске

**Для Chatwoot:**
```bash
docker compose -f docker-compose.prod.yml -p chatwoot up -d --remove-orphans
```

**Для Hi-Events:**
```bash
docker compose -p hievents up -d --remove-orphans
```

### 3. Уникальные container_name (Уже реализовано в Chatwoot)

В файлах docker-compose уже добавлены уникальные имена контейнеров:
- Production: `chatwoot-rails`, `chatwoot-sidekiq`, `chatwoot-postgres`, `chatwoot-redis`
- Development: `chatwoot-rails-dev`, `chatwoot-sidekiq-dev`, `chatwoot-postgres-dev`, `chatwoot-redis-dev`, `chatwoot-vite-dev`, `chatwoot-mailhog-dev`

## Рекомендуемые команды запуска

**Chatwoot Production:**
```bash
cd /opt/projects/chatwoot/current
docker compose -f docker-compose.prod.yml -p chatwoot up -d --remove-orphans
```

**Hi-Events:**
```bash
cd /opt/projects/hi-events/current
docker compose -p hievents up -d --remove-orphans
```

## Проверка контейнеров

Для проверки запущенных контейнеров:
```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

## Очистка конфликтующих контейнеров

Если контейнеры уже запущены с конфликтующими именами:
```bash
# Остановить все контейнеры
docker stop $(docker ps -q)

# Удалить контейнеры с конфликтующими именами
docker rm chatwoot-rails chatwoot-sidekiq chatwoot-postgres chatwoot-redis hi-events

# Перезапустить с уникальными именами проектов
```
