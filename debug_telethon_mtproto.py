#!/usr/bin/env python3
"""
Максимальный MTProto debug Telethon для сравнения
"""

import asyncio
import sys
import logging
import binascii
from telethon import TelegramClient

# Максимальный debug для MTProto
logging.basicConfig(
    level=logging.DEBUG,
    format='%(levelname)s:%(name)s: %(message)s'
)

# Включаем debug для всех MTProto слоев
loggers = [
    'telethon.network.mtprotoplainsender',
    'telethon.network.mtprotosender', 
    'telethon.network.authenticator',
    'telethon.network.mtprotostate',
    'telethon.network.connection',
    'telethon.tl'
]

for logger_name in loggers:
    logging.getLogger(logger_name).setLevel(logging.DEBUG)

api_id = 25442680
api_hash = 'e4365172396985cce0091f5de6e82305'
phone = '+79939108755'

async def main():
    print("🚀 Starting Telethon MAXIMUM MTProto debug...")

    # Delete session to force DH handshake
    import os
    try:
        os.remove('debug_mtproto_session.session')
        print("🗑️ Deleted existing session")
    except:
        pass

    client = TelegramClient('debug_mtproto_session', api_id, api_hash)

    try:
        print("📞 Connecting to Telegram...")
        await client.connect()

        print(f"📱 Sending code to {phone}...")
        result = await client.send_code_request(phone)
        print(f"✅ Code sent successfully!")

    except Exception as e:
        print(f"❌ Telethon debug test failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("🔌 Disconnecting...")
        await client.disconnect()

if __name__ == '__main__':
    asyncio.run(main())
