#!/usr/bin/env python3
"""
Максимально детальный debug Telethon для сравнения каждого MTProto сообщения
"""

import asyncio
import sys
import logging
import binascii
import time
from telethon import TelegramClient
from telethon.network import mtprotoplainsender, mtprotosender
from telethon.network.connection import tcpfull

# Patch MTProto senders to log everything
original_plain_send = mtprotoplainsender.MTProtoPlainSender.send
original_encrypted_send = mtprotosender.MTProtoSender.send

def patched_plain_send(self, request):
    print(f"📤 TELETHON PLAIN SEND: {type(request).__name__}")
    result = original_plain_send(self, request)
    if hasattr(result, '__await__'):
        async def wrapper():
            response = await result
            print(f"📥 TELETHON PLAIN RECV: {type(response).__name__}")
            return response
        return wrapper()
    else:
        print(f"📥 TELETHON PLAIN RECV: {type(result).__name__}")
        return result

def patched_encrypted_send(self, request):
    print(f"📤 TELETHON ENCRYPTED SEND: {type(request).__name__}")
    result = original_encrypted_send(self, request)
    if hasattr(result, '__await__'):
        async def wrapper():
            response = await result
            print(f"📥 TELETHON ENCRYPTED RECV: {type(response).__name__}")
            return response
        return wrapper()
    else:
        print(f"📥 TELETHON ENCRYPTED RECV: {type(response).__name__}")
        return result

mtprotoplainsender.MTProtoPlainSender.send = patched_plain_send
mtprotosender.MTProtoSender.send = patched_encrypted_send

# Также патчим TCP connection
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
    print("🚀 Starting DETAILED Telethon debug with hex dumps...")

    # Delete session to force fresh DH handshake
    import os
    try:
        os.remove('debug_detailed_session.session')
        print("🗑️ Deleted existing session - forcing fresh DH handshake")
    except:
        pass

    from telethon.network.connection import ConnectionTcpFull
    client = TelegramClient('debug_detailed_session', api_id, api_hash, connection=ConnectionTcpFull)
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
        print(f"❌ Telethon detailed debug failed: {e}")
        import traceback
        traceback.print_exc()
    finally:
        print("🔌 Disconnecting...")
        await client.disconnect()

if __name__ == '__main__':
    asyncio.run(main())
