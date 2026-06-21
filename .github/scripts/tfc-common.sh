#!/usr/bin/env bash
set -euo pipefail

TFC_API="https://app.terraform.io/api/v2"

# TFC_TOKEN環境変数を前提とする
tfc_api() {
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    curl -sS -f --request "$method" \
      --header "Authorization: Bearer ${TFC_TOKEN}" \
      --header "Content-Type: application/vnd.api+json" \
      --data "$body" \
      "${TFC_API}${path}"
  else
    curl -sS -f --request "$method" \
      --header "Authorization: Bearer ${TFC_TOKEN}" \
      --header "Content-Type: application/vnd.api+json" \
      "${TFC_API}${path}"
  fi
}

workspace_id_for() {
  local org="$1" name="$2"
  tfc_api GET "/organizations/${org}/workspaces/${name}" | jq -r '.data.id'
}
