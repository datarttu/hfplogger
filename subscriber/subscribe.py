"""
Save HFP MQTT messages of given topic
for given amount of DURATION.
"""

import os
import csv
import time
import logging
import argparse
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
    # Arguments are prioritized as follows:
    # 1) CL arguments 2) env variables 3) default values.
    descr = ('Subscribe to an HFP topic.\n'
             'Results and logs are saved relative to hfplogger/data/,\n',
             'or [HFPV2_ROOTDIR]/data/ if set.')
    parser = argparse.ArgumentParser(description='Subscribe to an HFP topic.')
    parser.add_argument('--host', help='MQTT host address', default='mqtt.hsl.fi')
    parser.add_argument('--port', help='MQTT port', type=int, default=1883)
    parser.add_argument('--topic',
                        help='MQTT topic, starts with /hfp/v2/...',
                        required=True)
    parser.add_argument('--fields',
                        help='Topic fields to include in result, separated by comma')
    parser.add_argument('--clientid',
                        help='MQTT client id to use instead of a random id',
                        type=str,
                        default=random_clientid())
    parser.add_argument('--duration',
                        help='Duration of subscription in seconds',
                        type=int,
                        default=5)
    parser.add_argument('--loglvl',
                        help='Logging level: debug, info, warning, or error',
                        type=str,
                        default='info')
    ar = parser.parse_args()

    HOST     = ar.host
    PORT     = ar.port
    TOPIC    = ar.topic
    FIELDS   = ar.fields
    CLIENTID = ar.clientid
    DURATION = ar.duration
    LOGLVL   = get_loglevel(ar.loglvl)
    # NOTE: Assuming this py script is located in hfplogger/subscriber/,
    #       so ".." points to hfplogger/.
    ROOTDIR  = os.getenv('HFPV2_ROOTDIR', '..')

    STARTTIME = datetime.utcnow()

    if FIELDS:
        FIELDS = [el.strip() for el in FIELDS.split(',')]
    else:
        FIELDS = TOPIC_FIELDS

    prefix = prefix_by_topic(TOPIC)
    logpath = autoname_path(directory=os.path.join(ROOTDIR, 'data', 'logs'),
                            template=f'{prefix}_%Y%m%d.log',
                            timestamp=STARTTIME)
    logformat = '[%(asctime)s]:%(levelname)s:%(filename)s:%(lineno)d: %(message)s'
    logging.basicConfig(filename=logpath,
                        level=LOGLVL,
                        format=logformat,
                        datefmt='%Y-%m-%d %H:%M:%S%z')
    logging.getLogger().addHandler(logging.StreamHandler())
    logging.info((f'HOST={HOST} '
                   f'PORT={PORT} '
                   f'TOPIC={TOPIC} '
                   f'FIELDS={FIELDS} '
                   f'CLIENTID={CLIENTID} '
                   f'DURATION={DURATION} '
                   f'LOGLVL={LOGLVL}'))

    respath = autoname_path(directory=os.path.join(ROOTDIR, 'data', 'raw'),
                            template=f'{prefix}_%Y%m%dT%H%M%SZ.csv',
                            timestamp=STARTTIME)

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
        logging.debug(f'Disconnected')
        if fobj is not None:
            fobj.close()
        if i == 0:
            logging.warning(f'{i} messages received.')
            if os.path.isfile(respath):
                logging.warning(f'Removing {respath}.')
                os.remove(respath)
        else:
            logging.info(f'{i} messages received')

if __name__ == "__main__":
    main()
