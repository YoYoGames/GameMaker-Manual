#!/usr/bin/env bash
set -euo pipefail

REPOS=(EN PT-BR DE ES FR IT JA KO PL RU ZH)
WORKFLOW="${WORKFLOW:-main.yml}"
GH_TOKEN="${GH_TOKEN:?GH_TOKEN is required}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:?SLACK_WEBHOOK_URL is required}"

RESULTS=""

echo "🔍 Collecting localisation build results..."

for LANG in "${REPOS[@]}"; do
  REPO="YoYoGames/GameMaker-Manual-$LANG"

  echo "➡️ Checking $REPO"

  # Get latest workflow run
  RUN_JSON=$(curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/workflows/$WORKFLOW/runs?per_page=1")

  RUN_ID=$(echo "$RUN_JSON" | jq -r '.workflow_runs[0].id')
  STATUS=$(echo "$RUN_JSON" | jq -r '.workflow_runs[0].status')
  CONCLUSION=$(echo "$RUN_JSON" | jq -r '.workflow_runs[0].conclusion')

  # Fallback safety
  if [[ "$RUN_ID" == "null" || -z "$RUN_ID" ]]; then
    RESULTS+=":warning: $LANG → No run found
"
    continue
  fi

  ARTIFACT_URL="https://github.com/$REPO/actions/runs/$RUN_ID#artifacts"

  # Format status
  if [[ "$CONCLUSION" == "success" ]]; then
    RESULTS+=":white_check_mark: $LANG → <$ARTIFACT_URL|Artifacts>
"
  elif [[ "$CONCLUSION" == "failure" ]]; then
    RESULTS+=":x: $LANG → <$ARTIFACT_URL|Artifacts>
"
  else
    RESULTS+=":warning: $LANG → <$ARTIFACT_URL|Artifacts> (status: $STATUS)
"
  fi

done

# -----------------------------
# 📦 Build Slack message safely
# -----------------------------
MSG=$(cat <<EOF
:package: *Localisation Build Artifacts*

$RESULTS
EOF
)

echo "📤 Sending Slack notification..."

curl -s -X POST -H 'Content-type: application/json' \
  --data "$(jq -n --arg text "$MSG" '{text: $text}')" \
  "$SLACK_WEBHOOK_URL"

echo "✅ Done"