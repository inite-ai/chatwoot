#!/usr/bin/env ruby
# frozen_string_literal: true

# Mock Rails for standalone testing
class Rails
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
  
  def self.root
    Pathname.new(Dir.pwd)
  end
end

require 'logger'
require 'pathname'
require_relative 'lib/telegram_m_t_proto_clean'

# Your credentials
API_ID = 25442680
API_HASH = 'e4365172396985cce0091f5de6e82305'
PHONE = '+79939108755'

def main
  puts "🚀 Starting our MTProto test..."
  
  begin
    puts "📱 Creating MTProto client..."
    client = TelegramMTProtoClean.new(API_ID, API_HASH, PHONE)
    
    puts "📞 Sending code request..."
    result = client.send_code
    
    if result[:success]
      puts "✅ Code sent successfully!"
      puts "📄 Phone code hash: #{result[:phone_code_hash]}"
      
      # Ask user for pin code
      print "🔢 Enter PIN code from SMS: "
      pin_code = gets.chomp
      
      puts "🔐 Would verify with code: #{pin_code}"
      puts "📝 (Verification not implemented yet, but we reached pin code input!)"
      
    else
      puts "❌ Failed to send code: #{result[:error]}"
    end
    
  rescue => e
    puts "❌ Exception: #{e.message}"
    puts "📋 Backtrace:"
    puts e.backtrace.join("\n")
  end
end

if __FILE__ == $0
  main
end
