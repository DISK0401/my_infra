#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-poll-run.sh <run_id> <timeout_seconds>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

run_id="$1"
timeout="${2:-600}"
elapsed=0
interval=10

# planned: 通常Runが確認待ちで停止する状態(applyを行う対象として扱う)
# planned_and_finished: speculative Runの完了状態
terminal_statuses="planned_and_finished applied errored discarded canceled force_canceled planned"

while [ "$elapsed" -lt "$timeout" ]; do
  status=$(tfc_api GET "/runs/${run_id}" | jq -r '.data.attributes.status')
  echo "status=${status}" >&2

  for s in $terminal_statuses; do
    if [ "$status" = "$s" ]; then
      echo "$status"
      exit 0
    fi
  done

  sleep "$interval"
  elapsed=$((elapsed + interval))
done

echo "ERROR: timed out waiting for run ${run_id}" >&2
exit 1
