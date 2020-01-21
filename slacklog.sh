#!/usr/bin/env bash
# Send messages to a Slack channel.
# `HFPV2_SLACK_WEBHOOK_URL`, `HFPV2_SLACK_CHANNEL` and `HFPV2_SLACK_USERNAME`
# MUST be defined in `.env` for this to work.
#
# NOTE: Does not work yet
envpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )""/.env"
[[ -f "$envpath" ]] && source "$envpath" || echo ".env file not found"
[[ -n "$HFPV2_SLACK_WEBHOOK_URL" ]] || echo "slacklog.sh: HFPV2_SLACK_WEBHOOK_URL missing from .env"
[[ -n "$HFPV2_SLACK_CHANNEL" ]] || echo "slacklog.sh: HFPV2_SLACK_CHANNEL missing from .env"
[[ -n "$HFPV2_SLACK_USERNAME" ]] || echo "slacklog.sh: HFPV2_SLACK_USERNAME missing from .env"
curl -s -X POST --data-urlencode \
"payload={\"channel\": \"$HFPV2_SLACK_CHANNEL\", \"username\": \"$HFPV2_SLACK_USERNAME\", \"text\": \"$1\"}" \
"$HFPV2_SLACK_WEBHOOK_URL" > /dev/null
echo ""
