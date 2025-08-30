#!/usr/bin/env python3
"""
Детальный hex debug Telethon MTProto messages для сравнения
"""

import asyncio
import sys
import logging
import binascii
from telethon import TelegramClient
from telethon.network.connection import Connection

# Patch Connection to log raw data
original_send = Connection.send
original_recv = Connection.recv

def patched_send(self, data):
    print(f"📤 TELETHON SEND HEX: {data.hex()}")
    return original_send(self, data)

def patched_recv(self, size):
    result = original_recv(self, size)
    if result:
        print(f"📥 TELETHON RECV HEX: {result.hex()}")
    return result

Connection.send = patched_send
Connection.recv = patched_recv

# Включаем minimal логирование 
logging.basicConfig(level=logging.WARNING)

api_id = 25442680
api_hash = 'e4365172396985cce0091f5de6e82305'
phone = '+79939108755'

async def main():
    print("🚀 Starting Telethon RAW MTProto debug...")

    # Delete existing session to force new DH handshake
    import os
    try:
        os.remove('debug_raw_session.session')
        print("🗑️ Deleted existing session")
    except:
        pass

    client = TelegramClient('debug_raw_session', api_id, api_hash)

    try:
        print("📞 Connecting to Telegram...")
        await client.connect()

        print(f"📱 Sending code to {phone}...")
        result = await client.send_code_request(phone)
        print(f"✅ Code sent successfully!")
        print(f"📄 Phone code hash: {result.phone_code_hash}")

    except Exception as e:
        print(f"❌ Telethon debug test failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("🔌 Disconnecting...")
        await client.disconnect()

if __name__ == '__main__':
    asyncio.run(main())
