class TelegramAccount::IncomingMessageService
  attr_reader :channel, :message_data

  def initialize(channel:, message_data:)
    @channel = channel
    @message_data = message_data
  end

  def perform
    # Находим или создаем контакт
    contact = find_or_create_contact
    
    # Находим или создаем conversation
    conversation = find_or_create_conversation(contact)
    
    # Создаем сообщение
    create_message(conversation)
  end

  private

  def find_or_create_contact
    telegram_user_id = message_data['from']['id'].to_s
    
    contact_inbox = channel.inbox.contact_inboxes.find_by(source_id: telegram_user_id)
    
    if contact_inbox
      contact_inbox.contact
    else
      # Создаем новый контакт
      contact_params = {
        account: channel.account,
        name: extract_contact_name,
        phone_number: message_data['from']['phone_number'],
        additional_attributes: {
          telegram_user_id: telegram_user_id,
          telegram_username: message_data['from']['username'],
          telegram_first_name: message_data['from']['first_name'],
          telegram_last_name: message_data['from']['last_name']
        }
      }
      
      contact = Contact.create!(contact_params)
      
      # Создаем связь contact_inbox
      ContactInbox.create!(
        contact: contact,
        inbox: channel.inbox,
        source_id: telegram_user_id
      )
      
      contact
    end
  end

  def find_or_create_conversation(contact)
    contact_inbox = contact.contact_inboxes.find_by(inbox: channel.inbox)
    
    # Ищем активную conversation или создаем новую
    conversation = contact_inbox.conversations.where(status: [:open, :pending]).last
    
    unless conversation
      conversation = Conversation.create!(
        account: channel.account,
        inbox: channel.inbox,
        contact: contact,
        contact_inbox: contact_inbox,
        additional_attributes: {
          telegram_chat_id: message_data['chat']['id'],
          telegram_chat_type: message_data['chat']['type']
        }
      )
    end
    
    conversation
  end

  def create_message(conversation)
    message_params = {
      account: channel.account,
      inbox: channel.inbox,
      conversation: conversation,
      message_type: :incoming,
      content: message_data['text'] || extract_media_caption,
      external_source_id_telegram: message_data['message_id'],
      sender: conversation.contact,
      created_at: Time.zone.at(message_data['date'])
    }

    message = Message.create!(message_params)
    
    # Обрабатываем вложения если есть
    process_attachments(message) if has_attachments?
    
    message
  end

  def extract_contact_name
    user = message_data['from']
    name_parts = [user['first_name'], user['last_name']].compact
    name_parts.any? ? name_parts.join(' ') : user['username'] || "Telegram User #{user['id']}"
  end

  def extract_media_caption
    message_data['caption'] || '[Media]'
  end

  def has_attachments?
    %w[photo video document audio voice sticker].any? { |type| message_data.key?(type) }
  end

  def process_attachments(message)
    # В реальной реализации здесь будет скачивание и прикрепление медиафайлов
    Rails.logger.info "Processing attachments for message #{message.id}"
    
    # Добавляем информацию о медиа в content
    media_info = extract_media_info
    if media_info
      message.update!(content: "#{message.content}\n\n[#{media_info}]")
    end
  end

  def extract_media_info
    case
    when message_data['photo']
      'Photo'
    when message_data['video']
      'Video'
    when message_data['document']
      "Document: #{message_data['document']['file_name']}"
    when message_data['audio']
      'Audio'
    when message_data['voice']
      'Voice Message'
    when message_data['sticker']
      'Sticker'
    else
      nil
    end
  end
end
