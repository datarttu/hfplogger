"""
Functions for HFP MQTT subscriber.
"""

import os
import string
import random
import logging
from datetime import datetime

# List all possible topic fields as of 2020-1,
# see https://digitransit.fi/en/developers/apis/4-realtime-api/vehicle-positions/#the-payload
TOPIC_FIELDS = ['desi', 'dir', 'oper', 'veh', 'tst', 'tsi', 'spd', 'hdg',
                'lat', 'long', 'acc', 'dl', 'odo', 'drst', 'oday', 'jrn',
                'line', 'start', 'loc', 'stop', 'route', 'occu', 'seq',
                'ttarr', 'ttdep', 'dr-type', 'tlp-requestid', 'tlp-requesttype',
                'tlp-prioritylevel', 'tlp-reason', 'tlp-att-seq', 'tlp-decision',
                'sid', 'signal-groupid', 'tlp-signalgroupnbr', 'tlp-line-configid',
                'tlp-point-configid', 'tlp-frequency', 'tlp-protocol']

def get_loglevel(level_str):
    """
    Get logging level from string.
    Empty or incorrect values result in ``ERROR`` level.
    """
    level_str = level_str.strip().lower()
    if level_str == 'notset':
        return 0
    elif level_str == 'debug':
        return 10
    elif level_str == 'info':
        return 20
    elif level_str == 'warning':
        return 30
    elif level_str == 'critical':
        return 50
    else:
        return 40

def prefix_by_topic(topic_str):
    """
    Return a topic-based prefix to produce distinct output files.

    ``prefix`` and ``version``, the first two elements,
    are ignored as they are always the same.
    ``journey_type`` is only included if it is NOT ``journey``.
    ``temporal_type`` is only included if it is NOT ``ongoing``.
    Last element of the topic (practically ``#``) is left out.
    See https://digitransit.fi/en/developers/apis/4-realtime-api/vehicle-positions/#the-topic
    """
    els = topic_str.split('/')[3:]
    if els[0] == 'journey':
        els[0] = None
    if els[1] == 'ongoing':
        els[1] = None
    els = [el for el in els[:-1] if el is not None]
    return '_'.join(els)

def autoname_path(directory, template, timestamp=None):
    """
    Return filepath string like ``[path]/[template]``.
    If ``path`` does not exist, create it.
    Time components in ``template``, e.g. ``%Y%m%d-%H%M``,
    use given ``timestamp`` (default: current time).
    """
    if not os.path.exists(directory):
        logging.debug(f'{directory} does not exist, creating')
        os.makedirs(directory)
    timestamp = timestamp or datetime.now()
    fname = timestamp.strftime(template)
    return os.path.join(directory, fname)

def random_clientid(length=10):
    """
    Generate random string for client id.
    """
    chars = string.ascii_letters + string.digits
    return ''.join(random.choice(chars) for i in range(length))
