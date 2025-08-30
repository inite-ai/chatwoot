#!/usr/bin/env ruby

class Rails
  def self.logger
    @logger ||= Class.new do
      def info(msg); end
      def error(msg); end  
      def debug(msg); end
      def warn(msg); end
    end.new
  end
end

require 'telegram_mtproto'

puts "🔍 Checking if sign_in method is accessible..."

client = TelegramMtproto.new(1, "test", "+1234")

if client.respond_to?(:sign_in)
  puts "✅ sign_in method is PUBLIC and accessible!"
else
  puts "❌ sign_in method is NOT accessible (probably private)"
end

# List all public methods containing 'sign'
public_methods = client.public_methods.select { |m| m.to_s.include?('sign') }
puts "📋 Public methods with 'sign': #{public_methods}"

# List all methods containing 'sign' 
all_methods = client.methods.select { |m| m.to_s.include?('sign') }
puts "📋 All methods with 'sign': #{all_methods}"
