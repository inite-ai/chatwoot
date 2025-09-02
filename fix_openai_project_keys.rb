# fix_openai_project_keys.rb
# This script patches the BaseOpenAiService to handle project-based OpenAI API keys correctly
# Project-based keys (sk-proj-*) already include organization info and don't need separate org ID

puts "🔧 Fixing OpenAI Project-based API Keys Support..."

file_path = '/app/enterprise/app/services/llm/base_open_ai_service.rb'

# Define the new content for the file
new_content = <<~RUBY_CODE
  class Llm::BaseOpenAiService
    DEFAULT_MODEL = 'gpt-4o-mini'.freeze

    def initialize
      Rails.logger.info 'OPENAI PATCH: Initializing OpenAI client'
      
      api_key = InstallationConfig.find_by!(name: 'CAPTAIN_OPEN_AI_API_KEY').value
      
      # Project-based keys (sk-proj-) already include organization info
      client_params = {
        access_token: api_key,
        uri_base: uri_base,
        log_errors: Rails.env.development?
      }
      
      # Only add organization for legacy keys
      unless api_key.start_with?('sk-proj-')
        org_id = organization_id
        client_params[:organization] = org_id if org_id.present?
        Rails.logger.info "OPENAI PATCH: Using organization ID: \#{org_id&.first(10)}..."
      else
        Rails.logger.info 'OPENAI PATCH: Using project-based key (no separate org ID needed)'
      end
      
      @client = OpenAI::Client.new(client_params)
      setup_model
    rescue StandardError => e
      Rails.logger.error "OPENAI PATCH: Failed to initialize: \#{e.message}"
      raise "Failed to initialize OpenAI client: \#{e.message}"
    end

    private

    def organization_id
      org_config = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ORGANIZATION')
      org_config&.value.presence || ENV['CAPTAIN_OPEN_AI_ORGANIZATION']
    end

    def uri_base
      endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
      endpoint.presence || 'https://api.openai.com/'
    end

    def setup_model
      config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
      @model = (config_value.presence || DEFAULT_MODEL)
    end
  end
RUBY_CODE

# Overwrite the file with the new content
File.write(file_path, new_content)
puts "✅ Successfully patched base_open_ai_service.rb for project-based keys"

puts "\n🎉 OpenAI Project Keys support completed!"
puts "\n📋 Notes:"
puts "1. Project-based API keys (sk-proj-*) work without Organization ID"
puts "2. Legacy keys still support Organization ID if needed"
puts "3. Restart the application: docker-compose restart chatwoot-rails chatwoot-sidekiq"
