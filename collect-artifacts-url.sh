set -euo pipefail

REPOS=(PT-BR DE ES FR IT JA KO PL RU ZH)
WORKFLOW=$WORKFLOW
GH_TOKEN=$GH_TOKEN

RESULTS=""

for LANG in "${REPOS[@]}"; do
  REPO="YoYoGames/GameMaker-Manual-$LANG"

  echo "🔍 Checking $REPO..."

  # Get latest run
  RUN_JSON=$(curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/$REPO/actions/workflows/$WORKFLOW/runs?per_page=1")

  RUN_ID=$(echo "$RUN_JSON" | jq -r '.workflow_runs[0].id')
  STATUS=$(echo "$RUN_JSON" | jq -r '.workflow_runs[0].status')
  CONCLUSION=$(echo "$RUN_JSON" | jq -r '.workflow_runs[0].conclusion')

  # Wait until completed
  for i in {1..30}; do
    if [[ "$STATUS" == "completed" ]]; then break; fi
    sleep 10

    RUN_JSON=$(curl -s -H "Authorization: token $GH_TOKEN" \
      "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID")

    STATUS=$(echo "$RUN_JSON" | jq -r '.status')
    CONCLUSION=$(echo "$RUN_JSON" | jq -r '.conclusion')
  done

  ARTIFACT_URL="https://github.com/$REPO/actions/runs/$RUN_ID#artifacts"

  if [[ "$CONCLUSION" == "success" ]]; then
    RESULTS+="✅ $LANG → <$ARTIFACT_URL|Artifacts>"
  elif [[ "$CONCLUSION" == "failure" ]]; then
    RESULTS+="❌ $LANG → <$ARTIFACT_URL|Artifacts>"
  else
    RESULTS+="⚠️ $LANG → <$ARTIFACT_URL|Artifacts> (status: $STATUS)"
  fi

done

MSG="📦 *Localisation Build Artifacts*

$(printf "%s\n" "${RESULTS[@]}")"

curl -X POST -H 'Content-type: application/json' \
  --data "$(jq -n --arg text "$MSG" '{text: $text}')" \
  "$SLACK_WEBHOOK_URL"
