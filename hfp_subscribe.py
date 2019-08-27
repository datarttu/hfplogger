"""
Establish an MQTT client and subscribe to Digitransit
HFP messages with given parameters.
"""

import paho.mqtt.client as mqtt
import argparse
import random
import string
import time
import os

i = 0

def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")

def on_message(client, userdata, msg):
    global i
    i += 1
    print(msg.topic + "\n" + msg.payload.decode("utf-8"))

def generate_client_id(prefix=None):
    """
    Generate a (unique) client id based on a prefix
    and current time. If no prefix given,
    use current username, or if not available,
    generate a random one.
    """
    if prefix is None:
        prefix = os.getenv("USER")
    if prefix is None:
        prefix = ''.join(random.choice(string.ascii_letters) for x in range(5))
    t = int(time.time())
    return f"{prefix}-{t}"

def main():
    parser = argparse.ArgumentParser(description="Subscribe to Digitransit MQTT.")
    parser.add_argument("-g", "--geohash_level", type=int,
                        help="Geohash level from 0 (least info) to 5 (most detailed)")
    args = parser.parse_args()

    client = mqtt.Client(client_id=generate_client_id())
    client.on_connect = on_connect
    client.on_message = on_message

    host = "mqtt.hsl.fi"
    port = 1883

    topic = "/hfp/v2/"
    topic += "journey/ongoing/vp/tram/"
    topic += "+/+/+/+/"
    topic += f"+/+/+/{args.geohash_level}/#"

    client.connect(host=host, port=port)
    client.subscribe("/hfp/v2/journey/ongoing/vp/tram/#")
    client.loop_start()
    time.sleep(5)
    client.loop_stop()
    client.disconnect()
    print(i)

if __name__ == "__main__":
    main()
