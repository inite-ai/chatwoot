#!/usr/bin/env python3
"""
Детальный debug Telethon для сравнения с нашей Ruby реализацией
"""

import asyncio
import sys
import logging
import binascii
from telethon import TelegramClient

# Настройка детального логирования
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Включаем debug для всех MTProto операций
logging.getLogger('telethon.network').setLevel(logging.DEBUG)
logging.getLogger('telethon.network.mtproto').setLevel(logging.DEBUG)
logging.getLogger('telethon.network.mtprotosender').setLevel(logging.DEBUG)
logging.getLogger('telethon.network.authenticator').setLevel(logging.DEBUG)

# Your credentials
api_id = 25442680
api_hash = 'e4365172396985cce0091f5de6e82305'
phone = '+79939108755'

async def main():
    print("🚀 Starting Telethon DEBUG test...")

    # Create client с подробным логированием
    client = TelegramClient('debug_session', api_id, api_hash)

    try:
        print("📞 Connecting to Telegram...")
        await client.connect()

        # Проверим, есть ли auth_key
        if not client.is_connected():
            print("❌ Not connected")
            return

        print(f"📱 Sending code to {phone}...")
        
        # Попробуем отправить код с детальным логированием
        result = await client.send_code_request(phone)

        print(f"✅ Code sent successfully!")
        print(f"📄 Result type: {type(result)}")
        print(f"📄 Phone code hash: {result.phone_code_hash}")
        
        # Дополнительная информация о сессии
        if hasattr(client._sender, '_state'):
            state = client._sender._state
            print(f"🔑 Auth key length: {len(state.auth_key.key) if state.auth_key else 0} bytes")
            print(f"⏰ Time offset: {state.time_offset}")
            print(f"🔢 Session ID: {state.id}")
            if state.auth_key:
                auth_key_id = int.from_bytes(state.auth_key.key[-8:], 'little', signed=True)
                print(f"🆔 Auth key ID: {auth_key_id}")

    except Exception as e:
        print(f"❌ Telethon debug test failed: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
    finally:
        print("🔌 Disconnecting...")
        await client.disconnect()

if __name__ == '__main__':
    asyncio.run(main())
