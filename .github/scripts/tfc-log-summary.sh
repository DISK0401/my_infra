#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-log-summary.sh <plan|apply> < log
#
# リポジトリは公開のため、PRコメントには属性値(連絡先・ARN等)を含めず、
# リソースごとの操作とサマリ、エラー見出しだけを出す。詳細はTFC側で確認する。
mode="$1"

case "$mode" in
  plan)
    grep -E '^\s*# \S+ (will|must) be |^\s*# \(imported from |^\s*# \S+ has moved to |^Plan: |^No changes\.|Error: ' \
      | sed -E 's/^[[:space:]│╷╵]*//; s/^(Error: [^:]*):.*/\1/' || true
    ;;
  apply)
    grep -E ': (Creation|Modifications|Destruction|Import) complete|^Apply complete!|Error: ' \
      | sed -E 's/^[[:space:]│╷╵]*//; s/ \[id=[^]]*\]//; s/^(Error: [^:]*):.*/\1/' || true
    ;;
  *)
    echo "unknown mode: $mode" >&2
    exit 2
    ;;
esac
