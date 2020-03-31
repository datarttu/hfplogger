# hfplogger: subscriber

This image / container subscribes to a given MQTT topic and saves the payload fields to a csv file.
It will only run for the given amount of seconds.

## Environment variables

|          	|                                                                                                          	|
|----------	|---------------------------------------------------------------------------------------------------------	|
| TOPIC    	| Required. E.g. `/hfp/v2/journey/ongoing/vp/metro/#`                                                      	|
| FIELDS   	| Optional but strongly recommended. Default: includes ALL possible fields. E.g. `desi dir long lat drst` 	|
| DURATION 	| Optional but strongly recommended: the subscription will run for this many seconds. Default: `5`         	|
| HOST     	| Optional. Default: `mqtt.hsl.fi`                                                                        	|
| PORT     	| Optional. Default: `1883`                                                                               	|
| CLIENTID 	| Optional. Default: random 10-character string.                                                          	|
| LOGLVL   	| Optional. Default: `error`. Alternatively, set this to `debug`.                                         	|

Optionally, you can provide these as lowercase command line arguments to the script, e.g.:

```
python subscribe.py --topic /hfp/v2/journey/ongoing/tlr/tram/# --duration 300
```

## Build & run

Example:

```
docker build -t hfp-subscriber .
docker run --rm -it -v "$(pwd)/data:/usr/src/app/data" \
  -e TOPIC="/hfp/v2/journey/ongoing/vp/metro/#" \
  -e LOGLVL="debug" \
  hfp-subscriber
```

## "received" field

Note that `received` is automatically added as the last field to every subscription, in case it is not already in the field definition.
This field tells the timestamp the message was received.
