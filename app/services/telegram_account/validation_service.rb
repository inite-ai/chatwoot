class TelegramAccount::ValidationService
  attr_reader :app_id, :app_hash, :phone_number

  def initialize(app_id:, app_hash:, phone_number:)
    @app_id = app_id
    @app_hash = app_hash
    @phone_number = phone_number
  end

  def valid_credentials?
    return false if app_id.blank? || app_hash.blank? || phone_number.blank?

    valid_app_id? && valid_app_hash? && valid_phone_number?
  end

  private

  def valid_app_id?
    # Базовая проверка формата app_id (должен быть числом)
    app_id.to_s.match?(/^\d+$/) && app_id.to_i > 0
  end

  def valid_app_hash?
    # Базовая проверка формата app_hash (32 символа hex)
    app_hash.match?(/^[a-f0-9]{32}$/i)
  end

  def valid_phone_number?
    # Базовая проверка формата номера телефона
    # Должен начинаться с + и содержать только цифры
    phone_number.match?(/^\+\d{10,15}$/)
  end
end
