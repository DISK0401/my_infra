#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-get-plan-log.sh <run_id>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

run_id="$1"

plan_id=$(tfc_api GET "/runs/${run_id}" | jq -r '.data.relationships.plan.data.id')
log_url=$(tfc_api GET "/plans/${plan_id}" | jq -r '.data.attributes."log-read-url"')

curl -sS -f "$log_url"
