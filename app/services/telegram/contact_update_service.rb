class Telegram::ContactUpdateService
  pattr_initialize [:contact!, :telegram_params!]

  def perform
    update_telegram_social_profile if should_update_telegram_profile?
  end

  private

  def should_update_telegram_profile?
    telegram_username.present? &&
      (contact.additional_attributes['social_profiles'].blank? ||
       contact.additional_attributes.dig('social_profiles', 'telegram').blank?)
  end

  def telegram_username
    @telegram_username ||= telegram_params[:username] ||
                           contact.additional_attributes['social_telegram_user_name'] ||
                           contact.additional_attributes['username']
  end

  def update_telegram_social_profile
    Rails.logger.info "Updating Telegram social profile for contact #{contact.id}"

    # Получаем текущие additional_attributes
    new_attributes = contact.additional_attributes.dup

    # Инициализируем social_profiles если их нет
    new_attributes['social_profiles'] ||= {}

    # Добавляем все социальные профили если их нет
    %w[facebook twitter linkedin github instagram].each do |platform|
      new_attributes['social_profiles'][platform] ||= ''
    end

    # Устанавливаем Telegram username
    new_attributes['social_profiles']['telegram'] = telegram_username

    # Обновляем контакт
    contact.update!(additional_attributes: new_attributes)

    Rails.logger.info "Telegram social profile updated for contact #{contact.id}"
  end
end
