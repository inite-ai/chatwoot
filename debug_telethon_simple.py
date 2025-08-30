#!/usr/bin/env python3
"""
Простой debug только TCP packets Telethon
"""

import asyncio
import sys
import logging
import binascii
import time
from telethon import TelegramClient
from telethon.network.connection import tcpfull

# Патчим только TCP connection
original_tcp_send = tcpfull.ConnectionTcpFull.send
original_tcp_recv = tcpfull.ConnectionTcpFull.recv

def patched_tcp_send(self, data):
    print(f"📡 TELETHON TCP SEND ({len(data)} bytes): {data.hex()}")
    return original_tcp_send(self, data)

def patched_tcp_recv(self, size=None):
    if size is None:
        result = original_tcp_recv(self)
    else:
        result = original_tcp_recv(self, size)
    
    if hasattr(result, '__await__'):
        async def wrapper():
            data = await result
            print(f"📡 TELETHON TCP RECV ({len(data)} bytes): {data.hex()}")
            return data
        return wrapper()
    else:
        print(f"📡 TELETHON TCP RECV ({len(result)} bytes): {result.hex()}")
        return result

tcpfull.ConnectionTcpFull.send = patched_tcp_send
tcpfull.ConnectionTcpFull.recv = patched_tcp_recv

# Отключаем лишние логи
logging.basicConfig(level=logging.ERROR)

api_id = 25442680
api_hash = 'e4365172396985cce0091f5de6e82305'
phone = '+79939108755'

async def main():
    print("🚀 Starting simple Telethon TCP debug...")

    # Delete session to force fresh DH handshake
    import os
    try:
        os.remove('debug_simple_session.session')
        print("🗑️ Deleted existing session - forcing fresh DH handshake")
    except:
        pass

    from telethon.network.connection import ConnectionTcpFull
    client = TelegramClient('debug_simple_session', api_id, api_hash, connection=ConnectionTcpFull)
    print(f"🔗 Using connection: {client._connection}")

    try:
        print("📞 Connecting to Telegram...")
        start_time = time.time()
        await client.connect()
        connect_time = time.time() - start_time
        print(f"✅ Connected in {connect_time:.2f}s")

        print(f"📱 Sending code to {phone}...")
        start_time = time.time()
        result = await client.send_code_request(phone)
        send_time = time.time() - start_time
        print(f"✅ Code sent in {send_time:.2f}s!")
        print(f"📄 Phone code hash: {result.phone_code_hash}")

    except Exception as e:
        print(f"❌ Telethon simple debug failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("🔌 Disconnecting...")
        await client.disconnect()

if __name__ == '__main__':
    asyncio.run(main())
