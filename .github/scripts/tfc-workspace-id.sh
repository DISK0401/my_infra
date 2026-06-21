#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-workspace-id.sh <org> <workspace_name>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

workspace_id_for "$1" "$2"
