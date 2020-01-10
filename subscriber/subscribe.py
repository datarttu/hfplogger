"""
Save HFP MQTT messages of given topic
for given amount of DURATION.
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

i = 0

def on_connect(client, userdata, flags, rc):
    if rc > 0:
        raise Exception(f'Connection refused with result code {rc}')
    logging.info(f'Connected with result code {rc}')

def on_message(client, userdata, msg):
    res = parse_message(msg, include=userdata['include'])
    userdata['writer'].writerow(res)
    global i
    i += 1

def main():
    HOST = os.getenv('HOST', 'mqtt.hsl.fi')
    PORT = int(os.getenv('PORT', 1883))
    TOPIC = os.getenv('TOPIC')
    FIELDS = os.getenv('FIELDS')
    CLIENTID = os.getenv('CLIENTID', random_clientid())
    DURATION = int(os.getenv('DURATION', 5))
    LOGLVL = get_loglevel(os.getenv('LOGLVL', 'ERROR'))
    STARTTIME = datetime.utcnow()

    if FIELDS:
        FIELDS = FIELDS.split(' ')
    else:
        FIELDS = TOPIC_FIELDS

    prefix = prefix_by_topic(TOPIC)
    logpath = autoname_path(directory='data/logs',
                            template=f'{prefix}_%Y%m%dT%H%M%SZ.log',
                            timestamp=STARTTIME)
    logging.basicConfig(filename=logpath, level=LOGLVL)
    logging.getLogger().addHandler(logging.StreamHandler())
    logging.debug((f'HOST={HOST} '
                   f'PORT={PORT} '
                   f'TOPIC={TOPIC} '
                   f'FIELDS={FIELDS} '
                   f'CLIENTID={CLIENTID} '
                   f'DURATION={DURATION} '
                   f'LOGLVL={LOGLVL}'))

    respath = autoname_path(directory='data/raw',
                            template=f'{prefix}_%Y%m%dT%H%M%SZ.csv',
                            timestamp=STARTTIME)
    resfile_exists = os.path.isfile(respath)

    # So that fobj can be referenced in the end even if the file object
    # to close then was never created:
    fobj = None

    # userdata dict passes objects to the Client callbacks.
    # We update it with the open file object only after a successful connection.
    userdata = {'include': FIELDS,
                'writer': None}

    client = mqtt.Client(client_id=CLIENTID,
                         userdata=userdata)
    client.on_connect = on_connect
    client.on_message = on_message

    if DURATION > 60:
        keepalive = 60
    else:
        keepalive = DURATION

    try:
        logging.debug('Connecting')
        client.connect(host=HOST, port=PORT, keepalive=keepalive)
        client.subscribe(TOPIC)

        logging.info(f'Saving csv to {respath}')
        fobj = open(respath, 'a')
        writer = csv.DictWriter(fobj, fieldnames=FIELDS, extrasaction='ignore')
        if not resfile_exists:
            logging.debug('Writing csv header line')
            writer.writeheader()
        userdata['writer'] = writer
        client.user_data_set(userdata)

        client.loop_start()
        logging.info(f'Subscription start: {datetime.utcnow()} UTC')
        time.sleep(DURATION)
        client.loop_stop()
        logging.info(f'Subscription end: {datetime.utcnow()} UTC')
    except:
        logging.exception('Error in subscription')
    finally:
        client.disconnect()
        logging.info(f'Disconnected')
        if fobj is not None:
            fobj.close()
        if i == 0:
            logging.warning(f'{i} messages received. Removing {respath}.')
            os.remove(respath)
        else:
            logging.info(f'{i} messages received')

if __name__ == "__main__":
    main()
