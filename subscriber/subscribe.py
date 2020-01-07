"""
Save HFP MQTT messages of given topic
for given amount of seconds.
"""

import os
import csv
import time
import logging
import paho.mqtt.client as mqtt
from datetime import datetime
from hfp.utils import get_loglevel
from hfp.utils import autoname_path
from hfp.utils import random_clientid
from hfp.utils import prefix_by_topic
from hfp.utils import TOPIC_FIELDS
from hfp.parse import parse_message

def on_connect(client, userdata, flags, rc):
    logging.info(f'Connected with result code {rc}')

def on_message(client, userdata, msg):
    res = parse_message(msg, include=userdata['include'])
    userdata['writer'].writerow(res)

def main():
    HOST = os.getenv('HOST', 'mqtt.hsl.fi')
    PORT = int(os.getenv('PORT', 1883))
    TOPIC = os.getenv('TOPIC')
    FIELDS = os.getenv('FIELDS')
    CLIENTID = os.getenv('CLIENTID', random_clientid())
    SECONDS = int(os.getenv('SECONDS', 5))
    LOGLVL = get_loglevel(os.getenv('LOGLVL', 'ERROR'))
    STARTTIME = datetime.now()

    prefix = prefix_by_topic(TOPIC)
    logpath = autoname_path(directory='data/logs',
                            template=f'{prefix}_%Y%m%d-%H%M.log',
                            timestamp=STARTTIME)
    logging.basicConfig(filename=logpath, level=LOGLVL)
    logging.getLogger().addHandler(logging.StreamHandler())
    logging.debug((f'HOST={HOST} '
                   f'PORT={PORT} '
                   f'TOPIC={TOPIC} '
                   f'FIELDS={FIELDS} '
                   f'CLIENTID={CLIENTID} '
                   f'SECONDS={SECONDS} '
                   f'LOGLVL={LOGLVL}'))

    respath = autoname_path(directory='data/raw',
                            template=f'{prefix}_%Y%m%d-%H%M.csv',
                            timestamp=STARTTIME)
    resfile_exists = os.path.isfile(respath)

    # Opened output file and field filter set must be prepared
    # for the client already
    logging.info(f'Saving to {respath}')
    if FIELDS:
        fields = FIELDS.split(' ')
    else:
        fields = TOPIC_FIELDS
    fobj = open(respath, 'a')
    writer = csv.DictWriter(fobj, fieldnames=fields, extrasaction='ignore')
    if not resfile_exists:
        writer.writeheader()

    client = mqtt.Client(client_id=CLIENTID,
                         userdata={'writer': writer, 'include': fields})
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
        fobj.close()
        logging.info(f'Ended at {datetime.now()}')

if __name__ == "__main__":
    main()
