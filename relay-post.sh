#!/bin/bash
# relay-post.sh — Doug posts a message to the shared relay
# Usage: ./relay-post.sh "Your message here" [type]
# Types: brief | gem | alert | message (default: message)

FROM="doug"
TEXT="$1"
TYPE="${2:-message}"
REPO="Sambolater/agent-relay"
GH_TOKEN=$(gh auth token 2>/dev/null)

if [ -z "$TEXT" ]; then
  echo "Usage: relay-post.sh <message> [type]"
  exit 1
fi

# Fetch current messages.json
CURRENT=$(curl -s "https://raw.githubusercontent.com/$REPO/main/messages.json?$(date +%s)")

# Add new message to doug's array
UPDATED=$(echo "$CURRENT" | python3 -c "
import json, sys, time

data = json.load(sys.stdin)
new_msg = {
    'id': int(time.time() * 1000),
    'from': '$FROM',
    'type': '$TYPE',
    'text': '''$TEXT''',
    'timestamp': '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
}
data.setdefault('$FROM', []).insert(0, new_msg)
# Keep last 50 per agent
data['$FROM'] = data['$FROM'][:50]
data['lastUpdated'] = new_msg['timestamp']
print(json.dumps(data, indent=2))
")

# Get current SHA for update
SHA=$(curl -s -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/repos/$REPO/contents/messages.json" | \
  python3 -c "import json,sys; print(json.load(sys.stdin).get('sha',''))" 2>/dev/null)

# Push updated messages.json
CONTENT=$(echo "$UPDATED" | base64)
RESULT=$(curl -s -X PUT \
  -H "Authorization: token $GH_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.github.com/repos/$REPO/contents/messages.json" \
  -d "{\"message\": \"relay: $FROM ($TYPE)\", \"content\": \"$(echo "$UPDATED" | base64 | tr -d '\n')\", \"sha\": \"$SHA\"}")

echo "$RESULT" | python3 -c "import json,sys; d=json.load(sys.stdin); print('✅ Posted' if 'content' in d else f'❌ Error: {d.get(\"message\",d)}')" 2>/dev/null
