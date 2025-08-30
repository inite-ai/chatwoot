class CreateChannelTelegramAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_telegram_accounts do |t|
      t.string :app_id, null: false
      t.string :app_hash, null: false
      t.string :phone_number, null: false
      t.text :session_string
      t.string :account_name
      t.boolean :is_active, default: false
      t.integer :account_id, null: false

      t.timestamps
    end

    add_index :channel_telegram_accounts, [:phone_number, :account_id], unique: true
    add_index :channel_telegram_accounts, :account_id
  end
end
