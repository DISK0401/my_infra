#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-find-run.sh <workspace_id> <commit_sha> <speculative:true|false>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

workspace_id="$1"
commit_sha="$2"
speculative="$3"

page=1
while [ "$page" -le 5 ]; do
  resp=$(tfc_api GET "/workspaces/${workspace_id}/runs?page%5Bnumber%5D=${page}&page%5Bsize%5D=20")
  run_count=$(echo "$resp" | jq '.data | length')
  if [ "$run_count" -eq 0 ]; then
    break
  fi

  ids=$(echo "$resp" | jq -r '.data[].id')
  for run_id in $ids; do
    cv_id=$(echo "$resp" | jq -r --arg id "$run_id" '.data[] | select(.id==$id) | .relationships."configuration-version".data.id')
    is_spec=$(echo "$resp" | jq -r --arg id "$run_id" '.data[] | select(.id==$id) | .attributes."plan-only"')

    if [ "$is_spec" != "$speculative" ]; then
      continue
    fi

    ingress=$(tfc_api GET "/configuration-versions/${cv_id}/ingress-attributes" 2>/dev/null || echo '{}')
    sha=$(echo "$ingress" | jq -r '.data.attributes."commit-sha" // empty')

    if [ "$sha" = "$commit_sha" ]; then
      echo "$run_id"
      exit 0
    fi
  done
  page=$((page + 1))
done

echo "ERROR: run not found for commit ${commit_sha} (speculative=${speculative})" >&2
exit 1
