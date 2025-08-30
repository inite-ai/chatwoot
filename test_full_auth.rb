#!/usr/bin/env ruby

require 'logger'

# Mock Rails logger for standalone testing
class Rails
  def self.logger
    @logger ||= Logger.new(STDOUT).tap do |log|
      log.level = Logger::INFO  # Change to DEBUG for more details
    end
  end
end

require_relative 'lib/telegram_m_t_proto_clean'

# FULL MTProto authentication test
def test_full_auth
  puts "\n🚀 ПОЛНЫЙ ТЕСТ MTProto АУТЕНТИФИКАЦИИ 🚀"
  puts "=" * 50
  
  # Your API credentials (same as before)
  api_id = 21296
  api_hash = "bf892b68ab6b6c03d7ed80da8524fe7b"
  phone = "+79266616789"  # Your phone number
  
  puts "📱 Phone: #{phone}"
  puts "🔑 API ID: #{api_id}"
  puts "🆔 API Hash: #{api_hash[0..10]}..."
  
  # Initialize MTProto client
  client = TelegramMTProtoClean.new(api_id, api_hash, phone)
  
  puts "\n📤 Step 1: Sending auth code..."
  result = client.send_code
  
  if result[:success]
    puts "✅ Code sent successfully!"
    puts "📄 Phone code hash: #{result[:phone_code_hash]}"
    
    # Ask for PIN code
    print "\n🔢 Enter PIN code from SMS: "
    pin_code = gets.chomp
    
    puts "\n🔐 Step 2: Signing in with PIN..."
    auth_result = client.sign_in(result[:phone_code_hash], pin_code)
    
    if auth_result[:success]
      puts "✅ Successfully authenticated!"
      puts "🎉 ПОЛНАЯ ПОБЕДА! MTProto auth flow завершен!"
    else
      puts "❌ Authentication failed: #{auth_result[:error]}"
    end
  else
    puts "❌ Failed to send code: #{result[:error]}"
  end
end

# Run the test
test_full_auth
