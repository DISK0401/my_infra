#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-find-run.sh <org> <workspace_id> <commit_sha> <speculative:true|false>
#
# Note: GET /workspaces/:id/runs (without any filter/search query) has been observed
# to return an empty result set for some workspaces even when runs exist, while
# GET /organizations/:org/runs?search[commit]=<sha> reliably returns matching runs.
# We therefore search at the organization level and filter by workspace client-side.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

org="$1"
workspace_id="$2"
commit_sha="$3"
speculative="$4"

resp=$(tfc_api GET "/organizations/${org}/runs?search%5Bcommit%5D=${commit_sha}")

run_id=$(echo "$resp" | jq -r --arg ws "$workspace_id" --arg spec "$speculative" \
  '.data[] | select(.relationships.workspace.data.id==$ws) | select((.attributes."plan-only"|tostring)==$spec) | .id' | head -n1)

if [ -z "$run_id" ]; then
  echo "ERROR: run not found for commit ${commit_sha} in workspace ${workspace_id} (speculative=${speculative})" >&2
  exit 1
fi

echo "$run_id"
