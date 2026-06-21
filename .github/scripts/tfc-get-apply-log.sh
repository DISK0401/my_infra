#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-get-apply-log.sh <run_id>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

run_id="$1"

apply_id=$(tfc_api GET "/runs/${run_id}" | jq -r '.data.relationships.apply.data.id')
log_url=$(tfc_api GET "/applies/${apply_id}" | jq -r '.data.attributes."log-read-url"')

curl -sS -f "$log_url"
