# Docker Cache Optimization Guide

## Проблемы с кешированием:

1. **Маленький Build Cache (10.9MB)** - указывает на неэффективное использование кеша
2. **Неоптимальный порядок слоев в Dockerfile**
3. **Частое копирование изменяющихся файлов**
4. **Использование default buildx driver без кеширования**

## Решения:

### 1. Настройка buildx с кешированием

```bash
# Создать новый builder с кешированием
docker buildx create --name mybuilder --driver docker-container --use
docker buildx inspect --bootstrap

# Использовать registry cache
docker buildx build --cache-from type=registry,ref=myregistry/cache \
                   --cache-to type=registry,ref=myregistry/cache \
                   --push -t myimage .
```

### 2. Оптимизация Dockerfile

```dockerfile
# Сначала копируем dependency файлы (редко изменяются)
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# Только потом копируем исходный код (часто изменяется)
COPY . /app

# Git SHA в конце, чтобы не инвалидировать кеш
RUN git rev-parse HEAD > /app/.git_sha || echo "unknown" > /app/.git_sha
```

### 3. Docker Compose оптимизация

```yaml
# Добавить в services
build:
  context: .
  dockerfile: ./docker/Dockerfile
  cache_from:
    - chatwoot:development
    - chatwoot:latest
```

### 4. .dockerignore файл

```
.git
node_modules
tmp/
log/
storage/
coverage/
*.log
```

## Команды для очистки и оптимизации:

```bash
# Проверить что занимает место
docker system df -v

# Очистить unused кеш но сохранить активный
docker builder prune --filter until=24h

# Оптимизированная сборка с кешем
docker-compose build --parallel
```

## Мониторинг кеша:

```bash
# Проверить использование кеша
docker buildx du

# Проверить размер образов
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```
