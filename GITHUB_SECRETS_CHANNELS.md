# GitHub Secrets для каналов связи Chatwoot

Этот документ содержит полный список GitHub Secrets, которые необходимо настроить в вашем репозитории для активации всех каналов связи в Chatwoot.

## Как добавить GitHub Secrets

1. Перейдите в ваш репозиторий на GitHub
2. Нажмите **Settings** → **Secrets and variables** → **Actions**
3. Нажмите **New repository secret**
4. Добавьте каждый secret из списка ниже

## Основные секреты

### База данных и инфраструктура
```
DB_PASSWORD - Пароль для PostgreSQL
REDIS_PASSWORD - Пароль для Redis
SECRET_KEY_BASE - Rails secret key (сгенерируйте с помощью: rails secret)
```

### Email и SMTP
```
MAIL_PASSWORD - Пароль для SMTP (например, от Mailgun)
```

### Docker Hub
```
DOCKERHUB_USERNAME - Имя пользователя Docker Hub
DOCKERHUB_TOKEN - Токен Docker Hub
```

## Секреты для каналов связи

### Facebook Messenger
```
FB_APP_ID - App ID из Facebook Developers
FB_APP_SECRET - App Secret из Facebook Developers  
FB_VERIFY_TOKEN - Webhook verify token (любая строка)
```

### Instagram
```
INSTAGRAM_APP_ID - Instagram App ID
INSTAGRAM_APP_SECRET - Instagram App Secret
INSTAGRAM_VERIFY_TOKEN - Instagram webhook verify token
```

### Google OAuth (Gmail)
```
GOOGLE_OAUTH_CLIENT_ID - Google OAuth Client ID
GOOGLE_OAUTH_CLIENT_SECRET - Google OAuth Client Secret
```
**Примечание:** GOOGLE_OAUTH_REDIRECT_URI автоматически формируется как `https://YOUR_DOMAIN/google/callback`

### Microsoft OAuth (Outlook/Office 365)
```
AZURE_APP_ID - Azure App Registration ID
AZURE_APP_SECRET - Azure App Secret
```

### WhatsApp Business API
```
WHATSAPP_APP_ID - WhatsApp App ID
WHATSAPP_APP_SECRET - WhatsApp App Secret
WHATSAPP_CONFIGURATION_ID - WhatsApp Configuration ID
```

### Telegram
```
TELEGRAM_BOT_TOKEN - Токен бота от @BotFather
```

### SMS (Twilio)
```
TWILIO_ACCOUNT_SID - Twilio Account SID
TWILIO_AUTH_TOKEN - Twilio Auth Token
```

### Captain AI (обязательно для работы AI ассистента)
```
CAPTAIN_OPEN_AI_API_KEY - OpenAI API ключ (обязательно для работы Captain AI)
CAPTAIN_FIRECRAWL_API_KEY - FireCrawl API ключ для веб-скрейпинга (опционально)
```

**⚠️ ВАЖНО:** `CAPTAIN_OPEN_AI_API_KEY` является обязательным секретом! Без него Captain AI будет показывать "Enterprise Paywall" даже при правильной настройке Enterprise режима.

**Примечание:** Остальные параметры Captain AI (модель, endpoint, embedding модель) настроены автоматически с разумными значениями по умолчанию в деплое.

## Пример настройки OAuth redirect URLs

### Google OAuth Console
- Authorized redirect URIs: `https://YOUR_DOMAIN/google/callback`

### Microsoft Azure App Registration  
- Redirect URIs: `https://YOUR_DOMAIN/microsoft/callback`

### Facebook App Settings
- Valid OAuth Redirect URIs: `https://YOUR_DOMAIN/facebook/callback`

## Проверка активации каналов

После добавления секретов и деплоя:

1. Зайдите в админ панель Chatwoot
2. Перейдите в **Settings** → **Inboxes** → **Add Inbox**
3. Проверьте, что нужные каналы теперь активны:
   - ✅ **Email** → Google (если GOOGLE_OAUTH_CLIENT_ID установлен)
   - ✅ **Email** → Microsoft (если AZURE_APP_ID установлен)
   - ✅ **Facebook** (если FB_APP_ID установлен)
   - ✅ **Instagram** (если INSTAGRAM_APP_ID установлен)
   - ✅ **WhatsApp** (если WHATSAPP_APP_ID установлен)
   - ✅ **Telegram** (если TELEGRAM_BOT_TOKEN установлен)
   - ✅ **SMS** (если TWILIO_ACCOUNT_SID установлен)

## Отладка

Если какой-то канал не активируется, проверьте:

1. **Логи деплоя:** `docker-compose logs chatwoot-rails`
2. **Переменные окружения в контейнере:**
   ```bash
   docker exec chatwoot-rails env | grep -E "(GOOGLE|AZURE|INSTAGRAM|FB_|WHATSAPP|TELEGRAM|TWILIO|CAPTAIN)"
   ```
3. **Frontend конфигурация:** откройте браузер и проверьте `window.chatwootConfig` в консоли

### Если Captain AI показывает "Enterprise Paywall"

1. **Проверьте системную конфигурацию:**
   ```bash
   docker exec chatwoot-rails bundle exec rails runner "
   puts 'Enterprise mode: ' + ChatwootApp.enterprise?.to_s
   puts 'IS_ENTERPRISE: ' + ENV['IS_ENTERPRISE'].to_s
   puts 'Captain API Key: ' + (ENV['CAPTAIN_OPEN_AI_API_KEY'].present? ? 'Present' : 'Missing')
   puts 'Pricing plan: ' + (GlobalConfig.get('INSTALLATION_PRICING_PLAN') || 'N/A')
   "
   ```
   Должно показывать:
   - `Enterprise mode: true`
   - `IS_ENTERPRISE: true` 
   - `Captain API Key: Present`
   - `Pricing plan: enterprise`

2. **Проверьте статус функций для аккаунтов:**
   ```bash
   docker exec chatwoot-rails bundle exec rails runner "
   Account.limit(5).each do |account|
     puts \"#{account.name}: captain_integration=#{account.feature_enabled?('captain_integration')}\"
   end"
   ```

3. **Запустите детальную диагностику и исправление:**
   ```bash
   docker exec chatwoot-rails bundle exec rails runner /app/enable_captain_ai.rb
   ```

4. **Если проблема с onboarding (повторный setup):**
   ```bash
   # Проверить статус onboarding
   docker exec chatwoot-rails bundle exec rails runner "
   puts 'Onboarding active: ' + Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING).to_s
   "
   
   # Если показывает true, отключить onboarding
   docker exec chatwoot-rails bundle exec rails runner "
   Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
   puts 'Onboarding disabled'
   "
   ```

5. **Перезапустите контейнеры после изменений:**
   ```bash
   docker-compose restart chatwoot-rails chatwoot-sidekiq
   ```

6. **Проверьте логи при проблемах:**
   ```bash
   docker-compose logs chatwoot-rails | grep -i captain
   docker-compose logs chatwoot-rails | grep -i enterprise
   ```

## Дополнительные настройки

### Webhooks URLs для внешних сервисов:
- **Facebook/Instagram:** `https://YOUR_DOMAIN/webhooks/facebook`
- **WhatsApp:** `https://YOUR_DOMAIN/webhooks/whatsapp`  
- **Telegram:** `https://YOUR_DOMAIN/webhooks/telegram`

### Callback URLs для OAuth:
- **Google:** `https://YOUR_DOMAIN/google/callback`
- **Microsoft:** `https://YOUR_DOMAIN/microsoft/callback`

Замените `YOUR_DOMAIN` на ваш фактический домен (например, `chat.inite.ai`).
