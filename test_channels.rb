#!/usr/bin/env ruby

# Тестирование конфигурации каналов
puts "=== Тестирование конфигурации Facebook и Instagram каналов ==="

# Проверяем InstallationConfig
fb_config = InstallationConfig.find_by(name: 'FB_APP_ID')
ig_config = InstallationConfig.find_by(name: 'INSTAGRAM_APP_ID')

puts "\n1. InstallationConfig в базе данных:"
puts "FB_APP_ID: #{fb_config&.value || 'НЕ НАЙДЕН'}"
puts "INSTAGRAM_APP_ID: #{ig_config&.value || 'НЕ НАЙДЕН'}"

# Проверяем GlobalConfig
GlobalConfig.clear_cache
fb_global = GlobalConfig.get('FB_APP_ID')['FB_APP_ID']
ig_global = GlobalConfig.get('INSTAGRAM_APP_ID')['INSTAGRAM_APP_ID']

puts "\n2. GlobalConfig (используется в приложении):"
puts "FB_APP_ID: #{fb_global || 'ПУСТОЙ'}"
puts "INSTAGRAM_APP_ID: #{ig_global || 'ПУСТОЙ'}"

# Проверяем feature flags для первого аккаунта
account = Account.first
if account
  puts "\n3. Feature flags для аккаунта '#{account.name}':"
  puts "channel_facebook: #{account.feature_enabled?('channel_facebook')}"
  puts "channel_instagram: #{account.feature_enabled?('channel_instagram')}"
else
  puts "\n3. Аккаунт не найден!"
end

puts "\n=== Тест завершен ==="
puts "Если все значения корректны, каналы должны быть активными в UI!"
