class AddPhoneCodeHashToChannelTelegramAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_telegram_accounts, :phone_code_hash, :string
  end
end
