#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-apply-and-report.sh <workspace_name> <commit_sha> <pr_number> <label>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

workspace_name="$1"
commit_sha="$2"
pr_number="$3"
label="$4"

ws_id=$(workspace_id_for "disk0401" "$workspace_name")
run_id=$("${script_dir}/tfc-find-run.sh" "$ws_id" "$commit_sha" false)

"${script_dir}/tfc-confirm-apply.sh" "$run_id"
status=$("${script_dir}/tfc-poll-run.sh" "$run_id" 900)

body_file=$(mktemp)
{
  if [ "$status" = "applied" ]; then
    echo "✅ \`${workspace_name}\` のApplyが完了しました。"
  else
    echo "❌ \`${workspace_name}\` のApplyが失敗しました(status: ${status})。"
  fi
  echo
  echo '```'
  "${script_dir}/tfc-get-apply-log.sh" "$run_id" | tail -c 60000
  echo '```'
  echo
  echo "[Terraform Cloudで詳細を見る](https://app.terraform.io/app/disk0401/workspaces/${workspace_name}/runs/${run_id})"
} > "$body_file"

"${script_dir}/post-pr-comment.sh" "$pr_number" "<!-- tfc-apply:${label} -->" "$body_file"
