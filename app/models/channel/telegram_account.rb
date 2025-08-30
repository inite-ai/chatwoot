# == Schema Information
#
# Table name: channel_telegram_accounts
#
#  id             :bigint           not null, primary key
#  app_id         :string           not null
#  app_hash       :string           not null
#  phone_number   :string           not null
#  session_string :text
#  account_name   :string
#  is_active      :boolean          default(FALSE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :integer          not null
#
# Indexes
#
#  index_channel_telegram_accounts_on_phone_number_and_account_id  (phone_number,account_id) UNIQUE
#

class Channel::TelegramAccount < ApplicationRecord
  include Channelable
  
  # Require MTProto gem
  require 'telegram_mtproto'

  self.table_name = 'channel_telegram_accounts'
  EDITABLE_ATTRS = [:app_id, :app_hash, :phone_number].freeze

  validates :app_id, presence: true
  validates :app_hash, presence: true
  validates :phone_number, presence: true, uniqueness: { scope: :account_id }

  # Validation moved to AuthenticationService to avoid double MTProto calls
  # before_save :validate_credentials, if: :new_record?
  after_create :setup_polling_service

  # Temporarily disable encryption for development
  # encrypts :app_hash, :session_string

  def name
    'Telegram Account'
  end

  def send_message_on_telegram(message)
    return unless active_session?
    
    TelegramAccount::SendMessageService.new(channel: self, message: message).perform
  end

  # MTProto authentication methods
  def send_auth_code
    Rails.logger.info "🔐 TelegramAccount#send_auth_code for #{phone_number}"
    
    mtproto_client = TelegramMtproto.new(app_id.to_i, app_hash, phone_number)
    result = mtproto_client.send_code
    
    if result[:success]
      Rails.logger.info "✅ Auth code sent successfully to #{phone_number}"
      update!(phone_code_hash: result[:phone_code_hash])
      result
    else
      Rails.logger.error "❌ Failed to send auth code: #{result[:error]}"
      result
    end
  end

  def authenticate_with_code(code)
    Rails.logger.info "🔐 TelegramAccount#authenticate_with_code for #{phone_number}"
    
    unless phone_code_hash.present?
      return { success: false, error: "No phone_code_hash - call send_auth_code first" }
    end
    
    mtproto_client = TelegramMtproto.new(app_id.to_i, app_hash, phone_number)
    result = mtproto_client.sign_in(phone_code_hash, code)
    
    if result[:success]
      Rails.logger.info "✅ Authentication successful for #{phone_number}"
      
      # Store session data for future use
      if mtproto_client.instance_variable_get(:@auth_key)
        auth_key_hex = mtproto_client.instance_variable_get(:@auth_key).unpack('H*')[0]
        update!(
          session_string: auth_key_hex,
          is_active: true
        )
      end
      
      result
    else
      Rails.logger.error "❌ Authentication failed: #{result[:error]}"
      result
    end
  end

  private

  def create_mtproto_client
    TelegramMTProtoClean.new(
      app_id.to_i,
      app_hash,
      phone_number
    )
  end

  # Get contacts using MTProto
  def get_telegram_contacts
    Rails.logger.info "📞 TelegramAccount#get_telegram_contacts for #{phone_number}"
    
    unless is_active?
      return { success: false, error: "Account not authenticated - call authenticate_with_code first" }
    end
    
    mtproto_client = TelegramMtproto.new(app_id.to_i, app_hash, phone_number)
    # TODO: Restore auth_key from session_string
    
    result = mtproto_client.get_contacts
    
    if result[:success]
      Rails.logger.info "✅ Got #{result[:contacts]&.length || 0} contacts from Telegram"
      result
    else
      Rails.logger.error "❌ Failed to get contacts: #{result[:error]}"
      result
    end
  end

  # Send message using MTProto
  def send_telegram_message(user_id, message_text)
    Rails.logger.info "📤 TelegramAccount#send_telegram_message to user_id=#{user_id}"
    
    unless is_active?
      return { success: false, error: "Account not authenticated - call authenticate_with_code first" }
    end
    
    mtproto_client = TelegramMtproto.new(app_id.to_i, app_hash, phone_number)
    # TODO: Restore auth_key from session_string
    
    result = mtproto_client.send_message(user_id, message_text)
    
    if result[:success]
      Rails.logger.info "✅ Message sent successfully to user_id=#{user_id}"
      result
    else
      Rails.logger.error "❌ Failed to send message: #{result[:error]}"
      result
    end
  end

  # Start receiving incoming messages  
  def start_message_polling
    Rails.logger.info "🔄 TelegramAccount#start_message_polling for #{phone_number}"
    
    unless is_active?
      return { success: false, error: "Account not authenticated - call authenticate_with_code first" }
    end
    
    mtproto_client = TelegramMtproto.new(app_id.to_i, app_hash, phone_number)
    # TODO: Restore auth_key from session_string
    
    # Define callback for incoming messages
    message_callback = proc do |message|
      Rails.logger.info "📥 Received message: '#{message[:message]}' from user_id=#{message[:from_id]}"
      
      # Create Chatwoot conversation and message
      create_conversation_from_telegram_message(message)
    end
    
    # Start polling in background
    @polling_thread = mtproto_client.start_updates_polling(message_callback)
    
    Rails.logger.info "✅ Message polling started for #{phone_number}"
    { success: true, polling_started: true }
  end

  # Stop message polling
  def stop_message_polling
    Rails.logger.info "🛑 TelegramAccount#stop_message_polling for #{phone_number}"
    
    if @mtproto_client
      @mtproto_client.stop_updates_polling
    end
    
    Rails.logger.info "✅ Message polling stopped for #{phone_number}"
  end

  private

  # Create Chatwoot conversation from Telegram message
  def create_conversation_from_telegram_message(message)
    Rails.logger.info "💬 Creating Chatwoot conversation from Telegram message"
    
    # Find or create contact
    contact = inbox.contacts.find_or_create_by(
      identifier: message[:from_id].to_s
    ) do |c|
      c.name = "Telegram User #{message[:from_id]}"
      c.account = account
    end
    
    # Find or create conversation
    conversation = inbox.conversations.find_or_create_by(
      contact: contact
    ) do |conv|
      conv.account = account
      conv.inbox = inbox
      conv.contact = contact
      conv.status = 'open'
    end
    
    # Create message
    Message.create!(
      account: account,
      inbox: inbox,
      conversation: conversation,
      contact: contact,
      content: message[:message],
      message_type: 'incoming',
      content_type: 'text',
      source_id: message[:id].to_s,
      created_at: Time.at(message[:date])
    )
    
    Rails.logger.info "✅ Created Chatwoot message from Telegram"
  rescue => e
    Rails.logger.error "❌ Failed to create Chatwoot message: #{e.message}"
  end

  def get_telegram_profile_image(user_id)
    return unless active_session?
    
    TelegramAccount::ProfileImageService.new(channel: self, user_id: user_id).perform
  end

  def active_session?
    session_string.present? && is_active?
  end

  def authenticate_with_code(code)
    TelegramAccount::AuthenticationService.new(channel: self).authenticate_with_code(code)
  end

  def authenticate_with_password(password)
    TelegramAccount::AuthenticationService.new(channel: self).authenticate_with_password(password)
  end

  def start_polling
    return unless active_session?
    
    TelegramAccount::PollingJob.perform_later(id)
  end

  def stop_polling
    # Логика остановки polling будет в PollingJob
  end

  private

  def validate_credentials
    # Валидация app_id и app_hash через реальный MTProto
    begin
      mtproto = TelegramMTProtoClean.new(app_id, app_hash, phone_number)
      result = mtproto.send_code
      
      unless result[:success]
        Rails.logger.error "❌ MTProto validation failed: #{result[:error]}"
        errors.add(:base, "Invalid Telegram credentials: #{result[:error]}")
        throw :abort
      end
      
      # Сохраняем phone_code_hash для последующего использования
      self.phone_code_hash = result[:phone_code_hash]
      
      Rails.logger.info "✅ MTProto validation successful, phone_code_hash: #{result[:phone_code_hash]}"
    rescue => e
      Rails.logger.error "❌ MTProto validation error: #{e.message}"
      errors.add(:base, "Failed to validate Telegram credentials: #{e.message}")
      throw :abort
    end
  end

  def setup_polling_service
    # Запускаем polling после создания канала
    TelegramAccount::SetupJob.perform_later(id)
  end
end
