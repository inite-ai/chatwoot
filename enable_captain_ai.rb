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

# Диагностическая информация
puts "\n🔍 System Information:"
puts "   Rails Environment: #{Rails.env}"
puts "   Enterprise mode: #{ChatwootApp.enterprise? rescue 'N/A'}"
puts "   Installation pricing plan: #{GlobalConfig.get('INSTALLATION_PRICING_PLAN') rescue 'N/A'}"
puts "   IS_ENTERPRISE env: #{ENV['IS_ENTERPRISE']}"
puts "   Captain AI API Key present: #{ENV['CAPTAIN_OPEN_AI_API_KEY'].present?}"

# Проверяем доступные фичи
available_features = begin
  YAML.safe_load(Rails.root.join('config/features.yml').read).map { |f| f['name'] }
rescue => e
  puts "   ⚠️ Could not load features.yml: #{e.message}"
  []
end

puts "   Available features: #{available_features.join(', ')}"

captain_related_features = available_features.select { |f| f.include?('captain') }
puts "   Captain-related features: #{captain_related_features.join(', ')}"

puts "\n" + "="*50

# Счетчики
total_accounts = 0
enabled_accounts = 0
already_enabled = 0

# Включаем Captain AI для всех аккаунтов
Account.find_each do |account|
  total_accounts += 1
  
  puts "\n📋 Account: #{account.name} (ID: #{account.id})"
  puts "   Current features: #{account.all_features.select { |k,v| v }.keys.join(', ')}"
  
  captain_integration_enabled = account.feature_enabled?('captain_integration')
  captain_enabled = begin
    account.feature_enabled?('captain')
  rescue
    false
  end
  
  puts "   captain_integration: #{captain_integration_enabled}"
  puts "   captain: #{captain_enabled}"
  
  if captain_integration_enabled && captain_enabled
    already_enabled += 1
    puts "   ✅ Already has Captain AI enabled"
  else
    begin
      # Enable captain_integration
      unless captain_integration_enabled
        account.enable_features!('captain_integration')
        puts "   🟢 Enabled captain_integration"
      end
      
      # Enable captain (if exists)
      unless captain_enabled
        begin
          account.enable_features!('captain')
          puts "   🟢 Enabled captain"
        rescue => e
          puts "   ⚠️ Could not enable captain feature: #{e.message}"
        end
      end
      
      enabled_accounts += 1
      puts "   ✅ Captain AI enabled"
    rescue => e
      puts "   ❌ Failed: #{e.message}"
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
