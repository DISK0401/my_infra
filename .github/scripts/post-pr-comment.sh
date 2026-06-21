#!/usr/bin/env bash
set -euo pipefail
# Usage: post-pr-comment.sh <pr_number> <marker> <body_file>
pr_number="$1"
marker="$2"
body_file="$3"

existing_id=$(gh api "repos/${GITHUB_REPOSITORY}/issues/${pr_number}/comments" --paginate \
  --jq ".[] | select(.body | startswith(\"${marker}\")) | .id" | head -n1)

tmp_body=$(mktemp)
{
  echo "$marker"
  cat "$body_file"
} > "$tmp_body"

if [ -n "$existing_id" ]; then
  gh api --method PATCH "repos/${GITHUB_REPOSITORY}/issues/comments/${existing_id}" \
    -f body=@"$tmp_body" > /dev/null
else
  gh api --method POST "repos/${GITHUB_REPOSITORY}/issues/${pr_number}/comments" \
    -f body=@"$tmp_body" > /dev/null
fi
