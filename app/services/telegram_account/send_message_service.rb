class TelegramAccount::SendMessageService
  attr_reader :channel, :message

  def initialize(channel:, message:)
    @channel = channel
    @message = message
  end

  def perform
    return unless channel.active_session?
    
    begin
      # В реальной реализации здесь будет отправка сообщения через MTProto API
      Rails.logger.info "Sending message via Telegram Account: #{message.content}"
      
      # Имитируем отправку сообщения
      chat_id = extract_chat_id_from_conversation
      
      # В реальности здесь будет вызов к Telegram MTProto API
      # Например: client.send_message(chat_id, message.content)
      
      # Возвращаем ID сообщения (в реальности получим от API)
      mock_message_id = SecureRandom.random_number(1000000)
      
      Rails.logger.info "Message sent successfully with ID: #{mock_message_id}"
      mock_message_id
    rescue StandardError => e
      Rails.logger.error "Failed to send message: #{e.message}"
      
      # Помечаем сообщение как неудачное
      message.external_error = e.message
      message.status = :failed
      message.save!
      
      nil
    end
  end

  private

  def extract_chat_id_from_conversation
    # Извлекаем chat_id из дополнительных атрибутов conversation
    conversation = message.conversation
    conversation.additional_attributes&.dig('telegram_chat_id') || 
    conversation.contact_inbox&.source_id
  end
end
