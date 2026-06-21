#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-confirm-apply.sh <run_id>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

run_id="$1"

tfc_api POST "/runs/${run_id}/actions/apply" '{"comment":"Applied via GitHub PR /apply comment"}' > /dev/null
echo "confirmed run ${run_id}" >&2
