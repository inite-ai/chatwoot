class Contacts::ContactableInboxesService
  pattr_initialize [:contact!]

  def get
    account = contact.account
    account.inboxes.filter_map { |inbox| get_contactable_inbox(inbox) }
  end

  private

  def get_contactable_inbox(inbox)
    method_name = channel_type_to_method_name(inbox.channel_type)
    return unless method_name

    send(method_name, inbox)
  end

  def channel_type_to_method_name(channel_type)
    {
      'Channel::TwilioSms' => :twilio_contactable_inbox,
      'Channel::Whatsapp' => :whatsapp_contactable_inbox,
      'Channel::Sms' => :sms_contactable_inbox,
      'Channel::Email' => :email_contactable_inbox,
      'Channel::Api' => :api_contactable_inbox,
      'Channel::WebWidget' => :website_contactable_inbox,
      'Channel::Telegram' => :telegram_contactable_inbox,
      'Channel::TelegramAccount' => :telegram_account_contactable_inbox
    }[channel_type]
  end

  def website_contactable_inbox(inbox)
    latest_contact_inbox = inbox.contact_inboxes.where(contact: @contact).last
    return unless latest_contact_inbox
    # FIXME : change this when multiple conversations comes in
    return if latest_contact_inbox.conversations.present?

    { source_id: latest_contact_inbox.source_id, inbox: inbox }
  end

  def api_contactable_inbox(inbox)
    latest_contact_inbox = inbox.contact_inboxes.where(contact: @contact).last
    source_id = latest_contact_inbox&.source_id || SecureRandom.uuid

    { source_id: source_id, inbox: inbox }
  end

  def email_contactable_inbox(inbox)
    return if @contact.email.blank?

    { source_id: @contact.email, inbox: inbox }
  end

  def whatsapp_contactable_inbox(inbox)
    return if @contact.phone_number.blank?

    # Remove the plus since thats the format 360 dialog uses
    { source_id: @contact.phone_number.delete('+'), inbox: inbox }
  end

  def sms_contactable_inbox(inbox)
    return if @contact.phone_number.blank?

    { source_id: @contact.phone_number, inbox: inbox }
  end

  def twilio_contactable_inbox(inbox)
    return if @contact.phone_number.blank?

    case inbox.channel.medium
    when 'sms'
      { source_id: @contact.phone_number, inbox: inbox }
    when 'whatsapp'
      { source_id: "whatsapp:#{@contact.phone_number}", inbox: inbox }
    end
  end

  def telegram_contactable_inbox(inbox)
    # Для Telegram Bot можно использовать существующий contact_inbox или создать новый
    latest_contact_inbox = inbox.contact_inboxes.where(contact: @contact).last
    source_id = latest_contact_inbox&.source_id || @contact.identifier || SecureRandom.uuid

    { source_id: source_id, inbox: inbox }
  end

  def telegram_account_contactable_inbox(inbox)
    # Для TelegramAccount тоже можем использовать contact_inbox или identifier
    latest_contact_inbox = inbox.contact_inboxes.where(contact: @contact).last
    source_id = latest_contact_inbox&.source_id || @contact.identifier || SecureRandom.uuid

    { source_id: source_id, inbox: inbox }
  end
end
