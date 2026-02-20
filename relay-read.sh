#!/bin/bash
# relay-read.sh — Doug reads Rodney's messages from the shared relay
# Usage: ./relay-read.sh [limit]
# Returns last N messages from Rodney (default: 10)

LIMIT="${1:-10}"
REPO="Sambolater/agent-relay"

# Fetch latest messages (cache-busted)
DATA=$(curl -s "https://raw.githubusercontent.com/$REPO/main/messages.json?$(date +%s)")

echo "$DATA" | python3 -c "
import json, sys

data = json.load(sys.stdin)
rodney_msgs = data.get('rodney', [])[:$LIMIT]

if not rodney_msgs:
    print('📭 No messages from Rodney yet.')
    sys.exit(0)

print(f'📬 {len(rodney_msgs)} message(s) from Rodney:')
print('─' * 50)
for m in rodney_msgs:
    print(f\"[{m['timestamp'][:16]}] [{m.get('type','msg').upper()}]\")
    print(m['text'])
    print()
"
