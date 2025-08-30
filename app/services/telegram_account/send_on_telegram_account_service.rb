class TelegramAccount::SendOnTelegramAccountService
  attr_reader :message

  def initialize(message:)
    @message = message
  end

  def perform
    return unless message.conversation.inbox.channel.active_session?

    message_id = message.conversation.inbox.channel.send_message_on_telegram(message)
    
    if message_id.present?
      message.update!(external_source_id_telegram: message_id)
    end
  end
end
