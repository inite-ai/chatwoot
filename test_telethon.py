#!/usr/bin/env python3
"""
Telethon test script to reach pin code input
"""

import asyncio
import sys
from telethon import TelegramClient

# Your credentials
api_id = 25442680
api_hash = 'e4365172396985cce0091f5de6e82305'
phone = '+79939108755'

async def main():
    print("🚀 Starting Telethon test...")
    
    # Create client with session file
    client = TelegramClient('test_session', api_id, api_hash)
    
    try:
        print("📞 Connecting to Telegram...")
        await client.connect()
        
        print(f"📱 Sending code to {phone}...")
        result = await client.send_code_request(phone)
        
        print(f"✅ Code sent successfully!")
        print(f"📄 Result type: {type(result)}")
        print(f"📄 Phone code hash: {result.phone_code_hash}")
        
        # Ask user for pin code
        pin_code = input("🔢 Enter PIN code from SMS: ")
        
        print(f"🔐 Signing in with code: {pin_code}")
        user = await client.sign_in(phone, pin_code)
        
        print(f"🎉 Successfully logged in as: {user.first_name}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        
    finally:
        print("🔌 Disconnecting...")
        await client.disconnect()

if __name__ == '__main__':
    asyncio.run(main())
