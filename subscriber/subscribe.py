"""
Save HFP MQTT messages of given topic
for given amount of seconds.
"""

import os
import time
import logging
import paho.mqtt.client as mqtt
from datetime import datetime
from hfp.utils import get_loglevel
from hfp.utils import autoname_path
from hfp.utils import random_clientid
from hfp.parse import parse_message

def on_connect(client, userdata, flags, rc):
    logging.info(f'Connected with result code {rc}')
    # TODO

def on_message(client, userdata, msg):
    print(parse_message(msg)
    # TODO:
    # Save filtered messages to an open file

def main():
    HOST = os.getenv('HOST', 'mqtt.hsl.fi')
    PORT = int(os.getenv('PORT', 1883))
    TOPIC = os.getenv('TOPIC')
    CLIENTID = os.getenv('CLIENTID', random_clientid())
    SECONDS = int(os.getenv('SECONDS', 5))
    LOGLVL = get_loglevel(os.getenv('LOGLVL', 'ERROR'))
    STARTTIME = datetime.now()

    logpath = autoname_path(directory='data/logs',
                            template='hfp_%Y%m%d-%H%M.log',
                            timestamp=STARTTIME)
    logging.basicConfig(filename=logpath, level=LOGLVL)
    logging.getLogger().addHandler(logging.StreamHandler())
    logging.debug((f'HOST={HOST} '
                   f'PORT={PORT} '
                   f'TOPIC={TOPIC} '
                   f'CLIENTID={CLIENTID} '
                   f'SECONDS={SECONDS} '
                   f'LOGLVL={LOGLVL}'))

    client = mqtt.Client(CLIENTID)
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(host=HOST, port=PORT)
    client.subscribe(TOPIC)
    try:
        client.loop_start()
        logging.info(f'Started at {datetime.now()}')
        time.sleep(SECONDS)
        client.loop_stop()
    except:
        logging.exception()
    finally:
        client.disconnect()
        logging.info(f'Ended at {datetime.now()}')

if __name__ == "__main__":
    main()
