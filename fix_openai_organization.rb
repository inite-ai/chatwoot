#!/usr/bin/env ruby
# frozen_string_literal: true

# Скрипт для исправления OpenAI Organization ID в Captain AI
# Использование: bundle exec rails runner fix_openai_organization.rb

puts "🔧 Fixing OpenAI Organization ID for Captain AI..."

# Patch BaseOpenAiService to include organization
base_service_path = Rails.root.join('enterprise/app/services/llm/base_open_ai_service.rb')

if File.exist?(base_service_path)
  puts "📝 Patching #{base_service_path}..."
  
  content = File.read(base_service_path)
  
  # Check if already patched
  if content.include?('organization:')
    puts "✅ Organization ID already configured"
  else
    # Add organization parameter
    old_client_init = <<~OLD
      @client = OpenAI::Client.new(
        access_token: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
        uri_base: uri_base,
        log_errors: Rails.env.development?
      )
    OLD
    
    new_client_init = <<~NEW
      @client = OpenAI::Client.new(
        access_token: InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value,
        organization: organization_id,
        uri_base: uri_base,
        log_errors: Rails.env.development?
      )
    NEW
    
    # Add organization_id method
    organization_method = <<~METHOD
    
      def organization_id
        org_config = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ORGANIZATION')
        org_config&.value.presence || ENV['CAPTAIN_OPEN_AI_ORGANIZATION']
      end
    METHOD
    
    # Apply patches
    new_content = content.gsub(old_client_init.strip, new_client_init.strip)
    new_content = new_content.gsub(/(\s+end\s*$)/, "#{organization_method}\\1")
    
    if new_content != content
      File.write(base_service_path, new_content)
      puts "✅ Successfully patched base_open_ai_service.rb"
    else
      puts "⚠️ No changes made to base_open_ai_service.rb"
    end
  end
else
  puts "❌ base_open_ai_service.rb not found at #{base_service_path}"
end

# Also create InstallationConfig for organization if it doesn't exist
puts "\n🔧 Setting up Organization ID config..."

begin
  org_config = InstallationConfig.find_or_initialize_by(name: 'CAPTAIN_OPEN_AI_ORGANIZATION')
  
  if org_config.new_record? || org_config.value.blank?
    org_id = ENV['CAPTAIN_OPEN_AI_ORGANIZATION']
    if org_id.present?
      org_config.value = org_id
      org_config.locked = false
      org_config.save!
      puts "✅ Created CAPTAIN_OPEN_AI_ORGANIZATION config with value: #{org_id[0..10]}..."
    else
      puts "⚠️ CAPTAIN_OPEN_AI_ORGANIZATION environment variable not found"
      puts "   Please add it to your deployment configuration"
    end
  else
    puts "✅ CAPTAIN_OPEN_AI_ORGANIZATION config already exists"
  end
rescue => e
  puts "❌ Error setting up organization config: #{e.message}"
end

puts "\n🎉 OpenAI Organization ID setup completed!"
puts "\n📋 Next steps:"
puts "1. Add CAPTAIN_OPEN_AI_ORGANIZATION to your GitHub Secrets"
puts "2. Restart the application: docker-compose restart chatwoot-rails chatwoot-sidekiq"
puts "3. Test Captain AI functionality"
