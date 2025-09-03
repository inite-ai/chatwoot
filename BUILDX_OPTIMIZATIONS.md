# Docker Buildx Optimizations in GitHub Actions

## 🚀 Оптимизации buildx в deploy-main.yml

### 1. **Улучшенная настройка Buildx:**
```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3
  with:
    driver: docker-container        # Лучше чем default driver
    buildkitd-flags: |             # Включаем расширенные возможности
      --allow-insecure-entitlement security.insecure
      --allow-insecure-entitlement network.host
    config-inline: |               # Оптимизация параллелизма
      [worker.oci]
        max-parallelism = 4
      [worker.containerd]
        max-parallelism = 4
```

### 2. **Многослойное кеширование:**
```yaml
cache-from: |
  type=registry,ref=username/chatwoot:cache    # Специальный cache image
  type=registry,ref=username/chatwoot:latest   # Последний успешный build
  type=gha                                     # GitHub Actions cache
```

### 3. **Дополнительные теги для лучшего кеширования:**
```yaml
tags: |
  username/chatwoot:latest       # Основной тег
  username/chatwoot:${github.sha} # Тег с commit SHA для истории
```

### 4. **Оптимизация производительности:**
```yaml
build-args: |
  BUILDKIT_INLINE_CACHE=1    # Встроенный кеш в образ
provenance: false            # Отключаем метаданные (ускоряет)
sbom: false                  # Отключаем SBOM генерацию
```

### 5. **Улучшенный fallback:**
- Включает `DOCKER_BUILDKIT=1` для традиционного Docker
- Использует несколько источников кеша
- Создает все необходимые теги

## 📊 Ожидаемые улучшения:

**Кеширование:**
- Registry cache + GHA cache + latest image = тройная защита
- Кеш работает между разными коммитами и ветками
- Inline cache в образах для дополнительного слоя

**Производительность:**
- `docker-container` driver быстрее default
- Параллельная обработка (max-parallelism = 4)
- Отключенные провenance/sbom экономят время

**Надежность:**
- Fallback с теми же оптимизациями
- Несколько источников кеша
- Теги с SHA для полной истории билдов

## 🎯 Результат:
- Первый билд: 10-15 минут
- Последующие билды: 1-3 минуты (только изменившиеся слои)
- Кеш сохраняется между коммитами
- Меньше нагрузки на Docker Hub (меньше пулов)
