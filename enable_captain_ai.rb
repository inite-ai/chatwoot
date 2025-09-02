#!/usr/bin/env ruby
# frozen_string_literal: true

# Скрипт для включения Captain AI для всех аккаунтов
# Использование: 
# В контейнере: bundle exec rails runner enable_captain_ai.rb
# Или напрямую: docker exec chatwoot-rails bundle exec rails runner /app/enable_captain_ai.rb

puts "🤖 Starting Captain AI enablement for all accounts..."

# Проверяем, что мы в правильном окружении
unless Rails.env.production? || Rails.env.development?
  puts "❌ This script should only be run in production or development environment"
  exit 1
end

# Проверяем наличие модели Account
unless defined?(Account)
  puts "❌ Account model not found. Make sure Rails is properly loaded."
  exit 1
end

# Счетчики
total_accounts = 0
enabled_accounts = 0
already_enabled = 0

# Включаем Captain AI для всех аккаунтов
Account.find_each do |account|
  total_accounts += 1
  
  if account.feature_enabled?('captain_integration')
    already_enabled += 1
    puts "✅ Account '#{account.name}' (ID: #{account.id}) already has Captain AI enabled"
  else
    begin
      account.enable_features!('captain_integration')
      enabled_accounts += 1
      puts "🟢 Enabled Captain AI for account '#{account.name}' (ID: #{account.id})"
    rescue => e
      puts "❌ Failed to enable Captain AI for account '#{account.name}' (ID: #{account.id}): #{e.message}"
    end
  end
end

puts "\n📊 Summary:"
puts "   Total accounts: #{total_accounts}"
puts "   Already enabled: #{already_enabled}"
puts "   Newly enabled: #{enabled_accounts}"
puts "   Failed: #{total_accounts - already_enabled - enabled_accounts}"

if enabled_accounts > 0
  puts "\n🎉 Successfully enabled Captain AI for #{enabled_accounts} accounts!"
else
  puts "\n✨ All accounts already have Captain AI enabled!"
end

puts "\n🔄 Restarting Rails application to apply changes..."
# В production с Docker Compose это перезапустит приложение
system("touch tmp/restart.txt") if File.directory?("tmp")

puts "✅ Captain AI enablement completed!"
