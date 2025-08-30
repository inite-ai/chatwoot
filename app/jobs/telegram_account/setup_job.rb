class TelegramAccount::SetupJob < ApplicationJob
  queue_as :default

  def perform(channel_id)
    @channel = Channel::TelegramAccount.find_by(id: channel_id)
    return unless @channel

    Rails.logger.info "Setting up Telegram Account channel #{channel_id}"
    
    # Ждем некоторое время для завершения создания канала
    sleep(2)
    
    # Если канал активен, запускаем polling
    if @channel.active_session?
      TelegramAccount::PollingJob.perform_later(channel_id)
      Rails.logger.info "Polling started for Telegram Account: #{@channel.phone_number}"
    end
  end
end
