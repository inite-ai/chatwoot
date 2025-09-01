# Конфигурация деплоя Chatwoot

## Основные настройки

Все настройки домена и проекта теперь собраны в одном месте в `.github/workflows/deploy-main.yml`:

```yaml
env:
  PROJECT_NAME: chatwoot
  DOMAIN: chat.inite.ai  # Замените на ваш домен
```

## Как работает конфигурация

### 1. Домен автоматически передается во все компоненты:

- **Traefik** - получает домен через лейблы Docker
- **Rails** - получает домен через `FRONTEND_URL`
- **Sidekiq** - работает в фоне для обработки задач
- **Database** - PostgreSQL с pgvector для AI функций
- **Redis** - для кэширования и очередей задач

### 2. HTTPS обрабатывается Traefik:

```
Интернет → Cloudflare (SSL) → Traefik (HTTP) → Rails (HTTP) → App
```

**Важно**: Traefik настроен на автоматическое получение SSL сертификатов через Let's Encrypt.

### 3. Архитектура деплоя:

```
rails:3000 ← HTTP ← Traefik:80/443
sidekiq      ← Background Jobs
postgres:5432 ← Database
redis:6379   ← Cache & Queues
```

## Деплой конфигурация

### Production деплой (`deploy.yml`)
- Полная конфигурация со всеми сервисами
- Traefik интеграция с SSL
- Автоматические миграции и health checks
- Оптимизированный Docker build
- Интеграция с Mailgun для email

## Активные GitHub Actions workflows

После очистки у нас остались только необходимые workflows:

- **deploy.yml** - production деплой
- **run_foss_spec.yml** - Ruby/Rails тесты
- **frontend-fe.yml** - Frontend тесты (JS/Vue)
- **lint_pr.yml** - проверка заголовков PR
- **size-limit.yml** - проверка размера JS бандла
- **auto-assign-pr.yml** - автоназначение PR

Удалены workflows связанные с официальным Chatwoot репозиторием:
- ~~deploy_check.yml~~ - проверка Heroku deployments
- ~~publish_foss_docker.yml~~ - публикация в chatwoot/chatwoot
- ~~publish_ee_docker.yml~~ - публикация Enterprise версии
- ~~nightly_installer.yml~~ - тестирование Linux installer
- ~~publish_codespace_image.yml~~ - GitHub Codespaces
- ~~test_docker_build.yml~~ - тестовый Docker build
- ~~logging_percentage_check.yml~~ - проверка логирования
- ~~stale.yml~~ - пометка старых PR
- ~~lock.yml~~ - блокировка issues

## Переменные окружения

**📋 Полный список переменных окружения и инструкции по настройке смотрите в [GITHUB_SECRETS.md](./GITHUB_SECRETS.md)**

### Краткий список обязательных секретов:

```bash
# Docker Hub
DOCKERHUB_USERNAME, DOCKERHUB_TOKEN

# Database  
DB_PASSWORD, REDIS_PASSWORD

# Rails
SECRET_KEY_BASE

# Email (SMTP) - только пароль
MAIL_PASSWORD  # остальные настройки захардкожены

# Facebook (опционально)
FB_VERIFY_TOKEN, FB_APP_SECRET, FB_APP_ID
```

> ⚠️ **Важно**: Добавьте все секреты в GitHub Repository Settings → Secrets and variables → Actions

## Для смены домена

1. Измените `DOMAIN` в `.github/workflows/deploy.yml`:
   ```yaml
   env:
     DOMAIN: your-new-domain.com
   ```

2. Сделайте commit и push - деплой произойдет автоматически

## Локальная разработка

Используйте стандартную конфигурацию:

```bash
# Установка зависимостей
bundle install && pnpm install

# Запуск разработки
pnpm dev
# или
overmind start -f ./Procfile.dev
```

## Структура проекта на сервере

```
/opt/projects/chatwoot/
├── current/              # Текущий деплой
├── backup-20240101_120000/  # Автоматические бэкапы
└── backup-20240102_150000/
```

## Troubleshooting

### 404 Not Found
- Проверьте, что домен правильно настроен в DNS
- Проверьте логи Traefik: `docker logs traefik-global`
- Проверьте статус сервисов: `docker-compose -f docker-compose.prod.yml ps`

### 500 Internal Server Error
- Проверьте логи Rails: `docker-compose -f docker-compose.prod.yml logs rails`
- Убедитесь, что миграции прошли: `docker-compose -f docker-compose.prod.yml exec rails bundle exec rails db:migrate:status`
- Проверьте переменные окружения в GitHub Secrets

### Database Connection Issues
- Проверьте статус PostgreSQL: `docker-compose -f docker-compose.prod.yml logs postgres`
- Убедитесь, что `DB_PASSWORD` корректный в секретах
- Проверьте health check базы данных

### ERR_TOO_MANY_REDIRECTS
- Убедитесь, что в Traefik нет конфликтующих правил
- Проверьте, что Cloudflare настроен правильно (если используется)

### SSL проблемы
- Убедитесь, что домен указывает на сервер с Traefik
- Проверьте Let's Encrypt логи в Traefik
- Проверьте, что порты 80 и 443 открыты на сервере

### Проблемы с памятью при билде
- Увеличьте `NODE_OPTIONS=--max-old-space-size=4096` в workflow
- Используйте fallback режим билда (автоматически включается при сбое BuildKit)

## Мониторинг и логи

```bash
# Логи всех сервисов
docker-compose -f docker-compose.prod.yml logs -f

# Логи конкретного сервиса
docker-compose -f docker-compose.prod.yml logs -f rails
docker-compose -f docker-compose.prod.yml logs -f sidekiq

# Статус сервисов
docker-compose -f docker-compose.prod.yml ps

# Использование ресурсов
docker stats
```

## Безопасность

- Все секреты хранятся в GitHub Secrets
- SSL сертификаты автоматически обновляются
- База данных доступна только из внутренней сети Docker
- Redis защищен паролем
- Логи не содержат чувствительной информации

## Backup и восстановление

### Автоматические бэкапы
- Старые деплои сохраняются автоматически
- Бэкапы старше 7 дней удаляются автоматически

### Ручной бэкап базы данных
```bash
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U postgres chatwoot > backup.sql
```

### Восстановление базы данных
```bash
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U postgres chatwoot < backup.sql
```
