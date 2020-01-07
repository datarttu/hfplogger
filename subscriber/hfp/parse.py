"""
Parse raw HFP MQTT messages.
"""

import json

# Assumed v2 event types as of 2020-1
EVENT_TYPES = {'VP', 'DUE', 'ARR', 'DEP', 'ARS', 'PDE', 'PAS', 'WAIT', 'DOO',
               'DOC', 'TLR', 'TLA', 'DA', 'DOUT', 'BA', 'BOUT', 'VJA', 'VJOUT'}

def parse_message(msg, include={}):
    """
    Parse raw HFP message, flatten into a simple dict
    where ``type`` (e.g. ``VP``) is one of the attributes.
    NOTE: Currently only handles the payload, not topic!

    ``include``: set of fields to return, others ignored.
    If empty, include all.
    """
    pld = json.loads(msg.payload)
    # Assuming there is only one top-level key
    msg_type = next(iter(pld.keys()))
    pld_vals = next(iter(pld.values()))
    if include:
        pld_vals = {key: value for key, value in pld_vals.items() if key in include}
    # Make from nested into flat dictionary:
    pld = {'type': msg_type, **pld_vals}
    return pld
