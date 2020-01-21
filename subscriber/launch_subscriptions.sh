#!/usr/bin/env bash
# Batch launch subscribe.py jobs in background.
set -o errexit

envpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )""/../.env"
[[ -f "$envpath" ]] && source "$envpath"

if [[ -z "$HFPV2_ROOTDIR" ]]; then
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
else
  DIR="$HFPV2_ROOTDIR""/subscriber"
fi
cd "$DIR"
source env/bin/activate
# The following loop reads one line at a time from subscriptions.txt
# and launches a subscription process for each line.
# There must be exactly 3 fields: topic, fields and duration,
# and they must be separated by ";".
# Note that the "&" after the python call leaves the process in background
# and lets the loop go to next step immediately.
IFS=";"
while read topic fields duration; do
  [[ "$topic" = \#* ]] || [[ -z "$topic" ]] && continue # Skip commented or empty lines
  python3 subscribe.py --topic "$topic" --fields "$fields" --duration "$duration" &
done<"../subscriptions.txt"
