# frozen_string_literal: true

# Active Record Encryption configuration
Rails.application.configure do
  # Generate a key for development/test environments
  # In production, use proper key management
  if Rails.env.development? || Rails.env.test?
    config.active_record.encryption.primary_key = 'dev-primary-key-' + ('a' * 24)
    config.active_record.encryption.deterministic_key = 'dev-deterministic-key-' + ('b' * 16)
    config.active_record.encryption.key_derivation_salt = 'dev-salt-' + ('c' * 24)
  else
    # In production, use environment variables or Rails credentials
    config.active_record.encryption.primary_key = ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY'] || Rails.application.credentials.active_record_encryption&.primary_key
    config.active_record.encryption.deterministic_key = ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY'] || Rails.application.credentials.active_record_encryption&.deterministic_key
    config.active_record.encryption.key_derivation_salt = ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT'] || Rails.application.credentials.active_record_encryption&.key_derivation_salt
  end
end
