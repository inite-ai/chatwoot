# Docker Build Optimization - КОНКРЕТНЫЕ РЕШЕНИЯ

## 🚨 ГЛАВНАЯ ПРОБЛЕМА: 
GitHub Actions пересобирает контейнеры каждый раз, потому что:
1. `COPY . /app` в Dockerfile инвалидирует кеш при любом изменении кода
2. `git rev-parse HEAD` генерирует новый SHA каждый коммит
3. GitHub Actions cache (type=gha) не помогает из-за изменяющегося контекста

## ✅ РЕШЕНИЯ:

### 1. ОПТИМИЗАЦИЯ DOCKERFILE (приоритет слоев):

```dockerfile
# Сначала DEPENDENCY файлы (редко меняются)
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json pnpm-lock.yaml ./  
RUN pnpm install

# ПОТОМ исходный код (часто меняется)
COPY . /app

# Git SHA в САМОМ КОНЦЕ (не влияет на предыдущие слои)
RUN git rev-parse HEAD > /app/.git_sha || echo "unknown" > /app/.git_sha
```

### 2. MULTI-STAGE BUILD для лучшего кеша:

```dockerfile
# Stage 1: Dependencies (кешируется долго)
FROM node:23-alpine as deps
COPY package.json pnpm-lock.yaml ./
RUN pnpm install

# Stage 2: Build (кешируется при изменении кода)
FROM ruby:3.4.5-alpine3.21 as builder
COPY --from=deps /node_modules ./node_modules
COPY Gemfile* ./
RUN bundle install
COPY . .
RUN build_commands_here

# Stage 3: Runtime (минимальный)
FROM ruby:3.4.5-alpine3.21
COPY --from=builder /app /app
```

### 3. GitHub Actions REGISTRY CACHE:

Заменить в .github/workflows/deploy-main.yml:
```yaml
# ВМЕСТО:
cache-from: type=gha
cache-to: type=gha,mode=max

# ИСПОЛЬЗОВАТЬ:
cache-from: |
  type=registry,ref=${{ secrets.DOCKERHUB_USERNAME }}/chatwoot:cache
  type=gha
cache-to: |
  type=registry,ref=${{ secrets.DOCKERHUB_USERNAME }}/chatwoot:cache,mode=max
  type=gha,mode=max
```

### 4. .dockerignore ОПТИМИЗАЦИЯ:

```
# Убрать из контекста все лишнее
.git
*.md
coverage/
spec/
test/
log/
tmp/
storage/
node_modules
```

## 🎯 РЕЗУЛЬТАТ:
- Первая сборка: 10-15 минут
- Последующие сборки: 2-5 минут (только изменившиеся слои)
- Registry cache работает между разными коммитами
- GHA cache + Registry cache = двойная защита

## 📊 ПРОВЕРКА ЭФФЕКТИВНОСТИ:

```bash
# Размер кеша
docker buildx du

# Время сборки
time docker build .

# Использование слоев
docker history chatwoot:latest
```
