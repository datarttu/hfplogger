"""
Functions for HFP MQTT subscriber.
"""

import os
import string
import random
import logging
from datetime import datetime

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
