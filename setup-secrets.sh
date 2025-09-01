#!/bin/bash

# Скрипт для быстрой настройки GitHub Secrets с помощью GitHub CLI
# Использование: ./setup-secrets.sh

set -e

echo "🔑 Настройка GitHub Secrets для Chatwoot"
echo ""

# Проверяем наличие GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI не установлен. Установите его с https://cli.github.com/"
    exit 1
fi

# Проверяем авторизацию
if ! gh auth status &> /dev/null; then
    echo "❌ Вы не авторизованы в GitHub CLI. Выполните: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI готов к работе"
echo ""

# Функция для безопасного ввода секрета
input_secret() {
    local secret_name="$1"
    local description="$2"
    local generate_option="$3"
    
    echo "📝 Настройка: $secret_name"
    echo "   Описание: $description"
    
    if [ "$generate_option" = "generate" ]; then
        echo "   🎲 Хотите сгенерировать случайное значение? [y/N]"
        read -r generate_choice
        if [[ $generate_choice =~ ^[Yy]$ ]]; then
            case $secret_name in
                "SECRET_KEY_BASE")
                    secret_value=$(openssl rand -hex 64)
                    ;;
                "DB_PASSWORD"|"REDIS_PASSWORD")
                    secret_value=$(openssl rand -base64 32)
                    ;;
                *)
                    echo "   ❌ Автогенерация не поддерживается для $secret_name"
                    return 1
                    ;;
            esac
            echo "   ✅ Сгенерировано: ${secret_value:0:20}..."
        else
            echo -n "   Введите значение: "
            read -r secret_value
        fi
    else
        echo -n "   Введите значение: "
        read -r secret_value
    fi
    
    if [ -n "$secret_value" ]; then
        if gh secret set "$secret_name" --body "$secret_value"; then
            echo "   ✅ $secret_name успешно добавлен"
        else
            echo "   ❌ Ошибка при добавлении $secret_name"
        fi
    else
        echo "   ⏭️  Пропущено (пустое значение)"
    fi
    echo ""
}

echo "🚀 Начинаем настройку обязательных секретов..."
echo ""

# Обязательные секреты
input_secret "DOCKERHUB_USERNAME" "Docker Hub username" ""
input_secret "DOCKERHUB_TOKEN" "Docker Hub access token (создайте на hub.docker.com/settings/security)" ""
input_secret "DB_PASSWORD" "Пароль для PostgreSQL" "generate"
input_secret "REDIS_PASSWORD" "Пароль для Redis" "generate"
input_secret "SECRET_KEY_BASE" "Rails secret key" "generate"

echo "📧 Email (SMTP) настройки - обязательны для уведомлений:"
echo "   📌 SMTP настройки предустановлены:"
echo "      • Email: chat@inite.ai (Chat Inite)" 
echo "      • Сервер: smtp.mailgun.org:2525"
input_secret "MAIL_PASSWORD" "Mailgun SMTP пароль" ""

echo "🔗 Facebook интеграция (опционально):"
echo "   Пропустите, если не нужна интеграция с Facebook"
input_secret "FB_VERIFY_TOKEN" "Facebook verify token" ""
input_secret "FB_APP_SECRET" "Facebook app secret" ""
input_secret "FB_APP_ID" "Facebook app ID" ""

echo ""
echo "✅ Настройка завершена!"
echo ""
echo "📋 Проверьте добавленные секреты:"
echo "   https://github.com/$(gh repo view --json owner,name -q '.owner.login + \"/\" + .name')/settings/secrets/actions"
echo ""
echo "🚀 Теперь можете запускать deployment workflows!"
echo ""
echo "💡 Полную документацию смотрите в GITHUB_SECRETS.md"
