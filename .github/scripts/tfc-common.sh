#!/usr/bin/env bash
set -euo pipefail

TFC_API="https://app.terraform.io/api/v2"

# TFC_TOKEN環境変数を前提とする
#
# TFC APIが一時的な5xxを返すことがあり(polling中に実際に観測済み)、
# --retry-all-errors で一時エラー・HTTPエラーの両方をリトライすることで、
# apply自体は進行中/成功しているのにレポート処理側だけが落ちて
# ワークフローが誤って失敗扱いになるのを防ぐ。
tfc_api() {
  local method="$1" path="$2" body="${3:-}"
  local retry_opts=(--retry 5 --retry-delay 3 --retry-all-errors)
  if [ -n "$body" ]; then
    curl -sS -f "${retry_opts[@]}" --request "$method" \
      --header "Authorization: Bearer ${TFC_TOKEN}" \
      --header "Content-Type: application/vnd.api+json" \
      --data "$body" \
      "${TFC_API}${path}"
  else
    curl -sS -f "${retry_opts[@]}" --request "$method" \
      --header "Authorization: Bearer ${TFC_TOKEN}" \
      --header "Content-Type: application/vnd.api+json" \
      "${TFC_API}${path}"
  fi
}

workspace_id_for() {
  local org="$1" name="$2"
  tfc_api GET "/organizations/${org}/workspaces/${name}" | jq -r '.data.id'
}
