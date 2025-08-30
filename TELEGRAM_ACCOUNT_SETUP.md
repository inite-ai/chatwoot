# Telegram Account Integration Setup

## Что было добавлено

В Chatwoot добавлена поддержка подключения персональных аккаунтов Telegram через MTProto API. Это позволяет:

- Подключить личный аккаунт Telegram (не бот)
- Авторизоваться через app_id, app_hash, номер телефона и PIN
- Получать и отправлять сообщения через подключенный аккаунт
- Поддержка двухфакторной аутентификации (2FA)

## Установка

### 1. Запустите миграцию базы данных

```bash
rails db:migrate
```

### 2. Получите API credentials от Telegram

1. Перейдите на https://my.telegram.org/apps
2. Войдите в свой аккаунт Telegram
3. Создайте новое приложение и получите:
   - **App ID** (числовой идентификатор)
   - **App Hash** (32-символьная строка)

### 3. Настройка в Chatwoot

1. Перейдите в **Settings → Inboxes → Add Inbox**
2. Выберите **Telegram Account**
3. Введите полученные App ID и App Hash
4. Введите свой номер телефона с кодом страны (например: +1234567890)
5. Нажмите **Send Verification Code**
6. Введите код, полученный в Telegram
7. Если у вас включена 2FA, введите пароль
8. Выберите агентов для inbox'а

## Архитектура

### Backend компоненты

- **Channel::TelegramAccount** - модель канала
- **TelegramAccount::AuthenticationService** - сервис авторизации
- **TelegramAccount::SendMessageService** - отправка сообщений
- **TelegramAccount::IncomingMessageService** - обработка входящих сообщений
- **TelegramAccount::PollingJob** - polling сообщений
- **Api::V1::Accounts::Channels::TelegramAccountsController** - API контроллер

### Frontend компоненты

- **TelegramAccount.vue** - UI для настройки канала
- Обновленные **ChannelFactory.vue** и **ChannelList.vue**
- Переводы в **inboxMgmt.json**

### База данных

Новая таблица `channel_telegram_accounts`:
- `app_id` - Telegram API ID
- `app_hash` - Telegram API Hash (зашифрован)
- `phone_number` - номер телефона
- `session_string` - строка сессии (зашифрована)
- `account_name` - имя аккаунта в Telegram
- `is_active` - статус активности

## Особенности реализации

### Заглушки для демонстрации

**ВАЖНО**: Текущая реализация содержит заглушки вместо реального MTProto API. Для production необходимо:

1. Добавить библиотеку для работы с Telegram MTProto API (например, телеграм-клиент на Ruby)
2. Заменить mock-методы в сервисах на реальные вызовы API
3. Настроить обработку ошибок и переподключение

### Реальная интеграция с Telegram API

Для полноценной работы потребуется:

```ruby
# Например, используя gem 'telegram-bot-ruby' или similar
class TelegramAccount::AuthenticationService
  def authenticate_with_code(code)
    client = TelegramClient.new(
      api_id: channel.app_id,
      api_hash: channel.app_hash
    )
    
    result = client.sign_in(
      phone_number: channel.phone_number,
      phone_code: code
    )
    
    if result.success?
      channel.update!(
        session_string: client.session_string,
        is_active: true,
        account_name: result.user.first_name
      )
    end
    
    result
  end
end
```

### Polling vs Webhooks

Поскольку пользовательские аккаунты Telegram не поддерживают webhooks, используется polling через `TelegramAccount::PollingJob`.

## Безопасность

- `app_hash` и `session_string` зашифрованы в базе данных
- Проверка валидности API credentials перед сохранением
- Уникальность номера телефона в рамках аккаунта

## Дальнейшие улучшения

1. **Реальная интеграция с MTProto API**
2. **Обработка медиафайлов** (фото, видео, документы)
3. **Поддержка групповых чатов**
4. **Статистика и мониторинг соединения**
5. **Автоматическое переподключение при разрыве сессии**

## Тестирование

После настройки:

1. Создайте Telegram Account inbox
2. Отправьте сообщение с другого аккаунта на подключенный номер
3. Ответьте через Chatwoot интерфейс
4. Проверьте, что сообщения синхронизируются

## Возможные проблемы

- **Telegram может заблокировать API** при превышении лимитов
- **Сессия может истечь** - потребуется повторная авторизация
- **2FA блокирует автоматизацию** - требует ручного ввода пароля

## Enterprise совместимость

Реализация совместима с Enterprise версией Chatwoot. При необходимости можно добавить:
- Дополнительные ограничения в `enterprise/app/models/enterprise/channel/telegram_account.rb`
- Расширенную аналитику
- Дополнительные настройки безопасности
