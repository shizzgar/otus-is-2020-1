import asyncio
import os
import json
import aiohttp



#HOST = os.getenv('HOST', '173.249.38.104')
HOST = os.getenv('HOST', 'localhost')

PORT = int(os.getenv('PORT', 8188))

URL = f'http://{HOST}:{PORT}/'
symbols = ['bnb', 'xlm', 'ada']


async def ws_channel(symbol):
    url = URL + symbol
    while True:
        try:
            session = aiohttp.ClientSession()

            async with session.ws_connect(url) as ws:

                await add_channel(ws)
                async for msg in ws:
                    print('Message received from server:', url, symbol, msg.data)

                    if msg.type in (aiohttp.WSMsgType.CLOSED,
                                    aiohttp.WSMsgType.ERROR):

                        break
            await session.close()
            await asyncio.sleep(5)
        except aiohttp.client_exceptions.ClientConnectionError as e:
            await session.close()
            await asyncio.sleep(5)




async def add_channel(ws):
    msg = {'action': 'start'}
    await ws.send_str(json.dumps(msg))


if __name__ == '__main__':
    print('Type "exit" to quit')
    loop = asyncio.get_event_loop()
    tasks = [asyncio.ensure_future(ws_channel(symbols[0])),
             asyncio.ensure_future(ws_channel(symbols[1])),
             asyncio.ensure_future(ws_channel(symbols[2]))
             ]
    loop.run_until_complete(asyncio.gather(*tasks))
