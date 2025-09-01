# GitHub Secrets для Chatwoot Deployment

Этот документ содержит полный список всех переменных окружения, которые нужно добавить в GitHub Secrets для корректной работы deployment workflows.

## 🔑 Обязательные Secrets

### Docker Hub
```bash
DOCKERHUB_USERNAME         # Ваш Docker Hub username
DOCKERHUB_TOKEN           # Docker Hub access token (не пароль!)
```

### База данных
```bash
DB_PASSWORD               # Пароль для PostgreSQL (используйте сильный пароль)
REDIS_PASSWORD           # Пароль для Redis (используйте сильный пароль)
```

### Rails приложение
```bash
SECRET_KEY_BASE          # Rails secret key (сгенерируйте с помощью: rails secret)
```

### Email (SMTP) - Обязательно для уведомлений
```bash
MAIL_PASSWORD           # Только пароль Mailgun (остальные настройки захардкожены)
```

**Предустановленные SMTP настройки:**
- Email отправителя: `chat@inite.ai` 
- Имя отправителя: `Chat Inite`
- SMTP сервер: `smtp.mailgun.org:2525`
- Домен: `inite.ai`

## 🔧 Опциональные Secrets

### Facebook (если нужна интеграция)
```bash
FB_VERIFY_TOKEN         # Facebook verify token
FB_APP_SECRET          # Facebook app secret
FB_APP_ID              # Facebook app ID
```

### Stripe (если нужны платежи)
```bash
STRIPE_SECRET_KEY      # Stripe secret key
STRIPE_WEBHOOK_SECRET  # Stripe webhook secret
```

### Другие интеграции (по необходимости)
```bash
# Twitter
TWITTER_APP_ID
TWITTER_CONSUMER_KEY
TWITTER_CONSUMER_SECRET

# Slack
SLACK_CLIENT_ID
SLACK_CLIENT_SECRET

# Google OAuth
GOOGLE_OAUTH_CLIENT_ID
GOOGLE_OAUTH_CLIENT_SECRET

# Azure/Microsoft
AZURE_APP_ID
AZURE_APP_SECRET

# OpenAI (для AI функций)
OPENAI_API_KEY

# AWS S3 (для cloud storage)
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
S3_BUCKET_NAME
AWS_REGION
```

## 🛠️ Как настроить GitHub Secrets

1. Перейдите в ваш GitHub репозиторий
2. Settings → Secrets and variables → Actions
3. Нажмите "New repository secret"
4. Добавьте каждый secret из списка выше

## 📝 Примеры значений

### Docker Hub Token
- Создайте на https://hub.docker.com/settings/security
- Выберите "Access Tokens" → "New Access Token"
- Скопируйте сгенерированный token

### SECRET_KEY_BASE
```bash
# Сгенерируйте локально:
rails secret
# или
openssl rand -hex 64
```

### Пароли для БД
```bash
# Используйте сильные пароли, например:
openssl rand -base64 32
```

### SMTP настройки

#### Gmail
```bash
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password  # НЕ обычный пароль, а App Password!
```

#### Mailgun
```bash
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
SMTP_USERNAME=postmaster@mg.yourdomain.com
SMTP_PASSWORD=your-mailgun-password
```

#### SendGrid
```bash
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your-sendgrid-api-key
```

## ⚠️ Важные заметки

1. **Никогда не коммитьте секреты в Git!**
2. **DOCKERHUB_TOKEN** - используйте именно access token, а не пароль
3. **Для Gmail** - включите 2FA и создайте App Password
4. **DB_PASSWORD** и **REDIS_PASSWORD** должны быть сильными
5. **SECRET_KEY_BASE** должен быть длинным hex-строкой

## 🔄 Автоматическое создание секретов

Можете использовать GitHub CLI для автоматического добавления:

```bash
# Установите GitHub CLI
# https://cli.github.com/

# Добавление секретов
gh secret set DOCKERHUB_USERNAME --body "your-username"
gh secret set DOCKERHUB_TOKEN --body "your-token"
gh secret set DB_PASSWORD --body "$(openssl rand -base64 32)"
gh secret set REDIS_PASSWORD --body "$(openssl rand -base64 32)"
gh secret set SECRET_KEY_BASE --body "$(openssl rand -hex 64)"

# и так далее...
```

## 📊 Статус настройки

Используйте этот чеклист для отслеживания прогресса:

- [ ] DOCKERHUB_USERNAME
- [ ] DOCKERHUB_TOKEN  
- [ ] DB_PASSWORD
- [ ] REDIS_PASSWORD
- [ ] SECRET_KEY_BASE
- [ ] MAIL_PASSWORD
- [ ] FB_VERIFY_TOKEN (опционально)
- [ ] FB_APP_SECRET (опционально)
- [ ] FB_APP_ID (опционально)

После настройки всех обязательных секретов ваш deployment workflow сможет успешно деплоить Chatwoot на ваш сервер!
