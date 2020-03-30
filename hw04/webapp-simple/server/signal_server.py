import asyncio
import os

import aiohttp.web
import logging
import threading
import time
import argparse
import random

HOST = os.getenv('HOST', '0.0.0.0')
PORT = int(os.getenv('PORT', 8188))

signals = {
    'ada': 0,
    'xlm': 0,
    'bnb': 0,
}


async def testhandle(request):
    return aiohttp.web.Response(text='Test handle')


def run_predictor(pair):
    previous = -1
    while True:
        try:
            signals[pair], previous = random.randint(1,100), random.randint(1,100)
        except Exception as e:
            logging.error(e)
        time.sleep(10)


class Handler:

    def __init__(self, args):
        self.args = args

    @staticmethod
    async def send_signals( ws, symbol):
        last_sent = ''
        while True:
            if last_sent != signals[symbol]:
                last_sent = signals[symbol]
                logging.info([symbol, last_sent])
                await ws.send_json(last_sent)
            await asyncio.sleep(10)

    @staticmethod
    async def send_test_signals(ws, symbol, model):

        while True:
            last_sent = signals[symbol]
            last_sent['model{}'.format(model)] = str(round(random.random(), 5))
            logging.info([symbol, last_sent])
            await ws.send_json(last_sent)
            await asyncio.sleep(10)

    async def websocket_handler(self, request):
        print('Websocket connection starting')
        symbol = request.match_info['name']
        ws = aiohttp.web.WebSocketResponse()
        await ws.prepare(request)
        print('Websocket connection ready')

        async for msg in ws:
            print(msg)
            if msg.type == aiohttp.WSMsgType.TEXT:
                print(msg.data)
                if msg.data == 'close':
                    await ws.close()
                else:
                    if self.args.testsymbol and \
                            self.args.testsymbol == symbol and \
                            self.args.testmodel:
                        await self.send_test_signals(ws, symbol, self.args.testmodel)
                    else:
                        await self.send_signals(ws, symbol)


        print('Websocket connection closed')
        return ws


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--connector', '-c',
                        help='Get connector: api, oracle',
                        default='api')
    parser.add_argument('--testsymbol', '-s',
                        help='test symbol: ada, bnb ...')
    parser.add_argument('--testmodel', '-m',
                        help='Test model: 1, 2 ...')
    return parser.parse_args()


def set_logger():
    handlers = []

    log_file = '/run/app/data/signal_server.log'
    handlers.append(logging.FileHandler(log_file))
    handlers.append(logging.StreamHandler())

    lglvl = logging.INFO
    logging.basicConfig(
        level=lglvl,
        format="%(asctime)s %(levelname)s %(message)s",
        handlers=handlers
    )


def main():
    args = get_args()
    set_logger()
    for key in signals.keys():
        t = threading.Thread(target=run_predictor, args=(key,))
        t.start()
    print('loop')
    app = aiohttp.web.Application()
    handler = Handler(args)
    app.router.add_route('GET', '/', testhandle)
    app.router.add_route('GET', '/{name}', handler.websocket_handler)
    aiohttp.web.run_app(app, host=HOST, port=PORT)


if __name__ == '__main__':
    main()
