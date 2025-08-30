class TelegramAccount::PollingJob < ApplicationJob
  queue_as :default

  def perform(channel_id)
    @channel = Channel::TelegramAccount.find_by(id: channel_id)
    return unless @channel&.active_session?

    Rails.logger.info "Starting Telegram Account polling for channel #{channel_id}"
    
    begin
      poll_messages
    rescue StandardError => e
      Rails.logger.error "Polling failed for channel #{channel_id}: #{e.message}"
      
      # Планируем повторную попытку через некоторое время
      self.class.set(wait: 30.seconds).perform_later(channel_id)
    end
  end

  private

  def poll_messages
    # В реальной реализации здесь будет polling через MTProto API
    # Например, получение обновлений через client.get_updates()
    
    Rails.logger.info "Polling messages for Telegram Account: #{@channel.phone_number}"
    
    # Имитируем получение сообщений
    # В реальности здесь будет:
    # updates = telegram_client.get_updates(offset: last_update_id)
    # updates.each { |update| process_update(update) }
    
    # Планируем следующий poll через 5 секунд
    if @channel.is_active?
      self.class.set(wait: 5.seconds).perform_later(@channel.id)
    end
  end

  def process_update(update)
    # Обрабатываем входящие сообщения
    # В реальности здесь будет парсинг обновлений от Telegram
    
    case update['type']
    when 'message'
      process_incoming_message(update['message'])
    when 'edited_message'
      process_edited_message(update['edited_message'])
    end
  rescue StandardError => e
    Rails.logger.error "Failed to process update: #{e.message}"
  end

  def process_incoming_message(message_data)
    # Создаем входящее сообщение в Chatwoot
    TelegramAccount::IncomingMessageService.new(
      channel: @channel,
      message_data: message_data
    ).perform
  end

  def process_edited_message(message_data)
    # Обрабатываем отредактированные сообщения
    # В Chatwoot можно добавить сообщение о том, что предыдущее было отредактировано
    Rails.logger.info "Message edited: #{message_data['message_id']}"
  end
end
