# Terraform Cloud PRベースApplyワークフロー Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PR作成時にTerraform CloudのSpeculative Plan結果をPRコメントで確認でき、マージ後は`/apply`コメントでTFCのRunを承認・apply実行し、結果をPRコメントで報告できるようにする。

**Architecture:** 2つのGitHub Actionsワークフロー(`tfc-plan-comment.yml`, `tfc-apply-comment.yml`)が、`.github/scripts/`配下の共通シェルスクリプトを介してTerraform Cloud API v2を操作する。Runの特定は、対象workspaceのRun一覧から各Runのconfiguration-versionに紐づく`ingress-attributes.commit-sha`と、PRのHEAD/マージコミットのSHAを突き合わせて行う。

**Tech Stack:** GitHub Actions、bash + curl + jq、GitHub CLI(`gh`)、Terraform Cloud API v2(`https://app.terraform.io/api/v2`)。

## Global Constraints

- TFC organization: `disk0401`
- 対象ワークスペース: `personal-aws`(working dir `terraform/environments/personal/aws`)、`personal-cloudflare`(working dir `terraform/environments/personal/cloudflare`)
- GitHub Secrets: `TFC_TOKEN`(対象ワークスペースのRunを確認(confirm)できる権限を持つTFC APIトークン)
- `/apply`コメントは、対象PRが**マージ済み**であり、かつコメント投稿者が`DISK0401`(リポジトリオーナー)である場合のみ許可する(本リポジトリはPublicであるため必須の認可チェック)
- このリポジトリの既定ブランチは`main`

---

### Task 1: TFC_TOKENシークレットの登録(人手)

**Files:** なし(GitHub UI上の操作)

- [ ] **Step 1: TFCでAPIトークンを発行する**

Terraform Cloud → Organization Settings(`disk0401`) → Teams → 該当チーム → Team API Token を発行する(`personal-aws`・`personal-cloudflare`双方のワークスペースに対してRunの確認権限を持つチームであること)。

- [ ] **Step 2: GitHub Secretsに登録する**

リポジトリ`DISK0401/my_infra`の Settings → Secrets and variables → Actions → New repository secret で、`TFC_TOKEN`という名前でStep 1のトークンを登録する。

---

### Task 2: TFC API共通スクリプトの作成

**Files:**
- Create: `.github/scripts/tfc-common.sh`

**Interfaces:**
- Produces: `tfc_api METHOD PATH [BODY]`(TFC APIを呼び出し、レスポンスJSONを標準出力に返す)、`workspace_id_for ORG WORKSPACE_NAME`(ワークスペースIDを標準出力に返す)。後続タスクの全スクリプトがこれを`source`する。

- [ ] **Step 1: tfc-common.shを作成する**

```bash
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
```

- [ ] **Step 2: シェル構文を確認する**

```bash
bash -n .github/scripts/tfc-common.sh
```

Expected: 何も出力されず終了コード0。

- [ ] **Step 3: 実行権限を付与してコミットする**

```bash
chmod +x .github/scripts/tfc-common.sh
git add .github/scripts/tfc-common.sh
git commit -m "feat: TFC API共通スクリプトを追加"
```

---

### Task 3: Run検索・ポーリングスクリプトの作成

**Files:**
- Create: `.github/scripts/tfc-find-run.sh`
- Create: `.github/scripts/tfc-poll-run.sh`

**Interfaces:**
- Consumes: `tfc-common.sh`の`tfc_api`
- Produces: `tfc-find-run.sh WORKSPACE_ID COMMIT_SHA SPECULATIVE`(該当Run IDを標準出力に返す。見つからない場合は終了コード1)、`tfc-poll-run.sh RUN_ID TIMEOUT_SECONDS`(Runが終端状態に達するまで待機し、最終ステータス文字列を標準出力に返す)

- [ ] **Step 1: tfc-find-run.shを作成する**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-find-run.sh <workspace_id> <commit_sha> <speculative:true|false>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

workspace_id="$1"
commit_sha="$2"
speculative="$3"

page=1
while [ "$page" -le 5 ]; do
  resp=$(tfc_api GET "/workspaces/${workspace_id}/runs?page%5Bnumber%5D=${page}&page%5Bsize%5D=20")
  run_count=$(echo "$resp" | jq '.data | length')
  if [ "$run_count" -eq 0 ]; then
    break
  fi

  ids=$(echo "$resp" | jq -r '.data[].id')
  for run_id in $ids; do
    cv_id=$(echo "$resp" | jq -r --arg id "$run_id" '.data[] | select(.id==$id) | .relationships."configuration-version".data.id')
    is_spec=$(echo "$resp" | jq -r --arg id "$run_id" '.data[] | select(.id==$id) | .attributes."plan-only"')

    if [ "$is_spec" != "$speculative" ]; then
      continue
    fi

    ingress=$(tfc_api GET "/configuration-versions/${cv_id}/ingress-attributes" 2>/dev/null || echo '{}')
    sha=$(echo "$ingress" | jq -r '.data.attributes."commit-sha" // empty')

    if [ "$sha" = "$commit_sha" ]; then
      echo "$run_id"
      exit 0
    fi
  done
  page=$((page + 1))
done

echo "ERROR: run not found for commit ${commit_sha} (speculative=${speculative})" >&2
exit 1
```

- [ ] **Step 2: tfc-poll-run.shを作成する**

```bash
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
```

- [ ] **Step 3: シェル構文を確認する**

```bash
bash -n .github/scripts/tfc-find-run.sh
bash -n .github/scripts/tfc-poll-run.sh
```

Expected: 両方とも何も出力されず終了コード0。

- [ ] **Step 4: 実行権限を付与してコミットする**

```bash
chmod +x .github/scripts/tfc-find-run.sh .github/scripts/tfc-poll-run.sh
git add .github/scripts/tfc-find-run.sh .github/scripts/tfc-poll-run.sh
git commit -m "feat: TFC Run検索・ポーリングスクリプトを追加"
```

---

### Task 4: ログ取得・Apply確認スクリプトの作成

**Files:**
- Create: `.github/scripts/tfc-get-plan-log.sh`
- Create: `.github/scripts/tfc-get-apply-log.sh`
- Create: `.github/scripts/tfc-confirm-apply.sh`

**Interfaces:**
- Consumes: `tfc-common.sh`の`tfc_api`
- Produces: `tfc-get-plan-log.sh RUN_ID`(plan本文を標準出力に返す)、`tfc-get-apply-log.sh RUN_ID`(apply本文を標準出力に返す)、`tfc-confirm-apply.sh RUN_ID`(該当RunのApplyを確認する)

- [ ] **Step 1: tfc-get-plan-log.shを作成する**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-get-plan-log.sh <run_id>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

run_id="$1"

plan_id=$(tfc_api GET "/runs/${run_id}" | jq -r '.data.relationships.plan.data.id')
log_url=$(tfc_api GET "/plans/${plan_id}" | jq -r '.data.attributes."log-read-url"')

curl -sS -f "$log_url"
```

- [ ] **Step 2: tfc-get-apply-log.shを作成する**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-get-apply-log.sh <run_id>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

run_id="$1"

apply_id=$(tfc_api GET "/runs/${run_id}" | jq -r '.data.relationships.apply.data.id')
log_url=$(tfc_api GET "/applies/${apply_id}" | jq -r '.data.attributes."log-read-url"')

curl -sS -f "$log_url"
```

- [ ] **Step 3: tfc-confirm-apply.shを作成する**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-confirm-apply.sh <run_id>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

run_id="$1"

tfc_api POST "/runs/${run_id}/actions/apply" '{"comment":"Applied via GitHub PR /apply comment"}' > /dev/null
echo "confirmed run ${run_id}" >&2
```

- [ ] **Step 4: シェル構文を確認する**

```bash
bash -n .github/scripts/tfc-get-plan-log.sh
bash -n .github/scripts/tfc-get-apply-log.sh
bash -n .github/scripts/tfc-confirm-apply.sh
```

Expected: いずれも何も出力されず終了コード0。

- [ ] **Step 5: 実行権限を付与してコミットする**

```bash
chmod +x .github/scripts/tfc-get-plan-log.sh .github/scripts/tfc-get-apply-log.sh .github/scripts/tfc-confirm-apply.sh
git add .github/scripts/tfc-get-plan-log.sh .github/scripts/tfc-get-apply-log.sh .github/scripts/tfc-confirm-apply.sh
git commit -m "feat: TFCログ取得・Apply確認スクリプトを追加"
```

---

### Task 5: PRコメント投稿スクリプトの作成

**Files:**
- Create: `.github/scripts/post-pr-comment.sh`

**Interfaces:**
- Consumes: 環境変数`GITHUB_TOKEN`、`GITHUB_REPOSITORY`(GitHub Actions実行時に自動設定される)
- Produces: `post-pr-comment.sh PR_NUMBER MARKER BODY_FILE`(`MARKER`を本文先頭に含む既存コメントがあれば更新、なければ新規作成する)

- [ ] **Step 1: post-pr-comment.shを作成する**

```bash
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
```

- [ ] **Step 2: シェル構文を確認する**

```bash
bash -n .github/scripts/post-pr-comment.sh
```

Expected: 何も出力されず終了コード0。

- [ ] **Step 3: 実行権限を付与してコミットする**

```bash
chmod +x .github/scripts/post-pr-comment.sh
git add .github/scripts/post-pr-comment.sh
git commit -m "feat: PRコメント投稿スクリプトを追加"
```

---

### Task 6: Apply実行・報告スクリプトの作成

**Files:**
- Create: `.github/scripts/tfc-apply-and-report.sh`

**Interfaces:**
- Consumes: `tfc-common.sh`の`workspace_id_for`、`tfc-find-run.sh`、`tfc-confirm-apply.sh`、`tfc-poll-run.sh`、`tfc-get-apply-log.sh`、`post-pr-comment.sh`
- Produces: `tfc-apply-and-report.sh WORKSPACE_NAME COMMIT_SHA PR_NUMBER LABEL`(該当Runを確認・apply・結果をPRコメントで報告する一連の処理)

- [ ] **Step 1: tfc-apply-and-report.shを作成する**

```bash
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
```

- [ ] **Step 2: シェル構文を確認する**

```bash
bash -n .github/scripts/tfc-apply-and-report.sh
```

Expected: 何も出力されず終了コード0。

- [ ] **Step 3: 実行権限を付与してコミットする**

```bash
chmod +x .github/scripts/tfc-apply-and-report.sh
git add .github/scripts/tfc-apply-and-report.sh
git commit -m "feat: TFC Apply実行・報告スクリプトを追加"
```

---

### Task 7: tfc-workspace-id.shヘルパーとPlanコメントワークフローの作成

**Files:**
- Create: `.github/scripts/tfc-workspace-id.sh`
- Create: `.github/workflows/tfc-plan-comment.yml`

**Interfaces:**
- Consumes: `tfc-common.sh`の`workspace_id_for`、`tfc-find-run.sh`、`tfc-poll-run.sh`、`tfc-get-plan-log.sh`、`post-pr-comment.sh`
- Produces: `tfc-workspace-id.sh ORG WORKSPACE_NAME`(ワークスペースIDを標準出力に返す)

- [ ] **Step 1: tfc-workspace-id.shを作成する**

```bash
#!/usr/bin/env bash
set -euo pipefail
# Usage: tfc-workspace-id.sh <org> <workspace_name>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${script_dir}/tfc-common.sh"

workspace_id_for "$1" "$2"
```

- [ ] **Step 2: 実行権限を付与する**

```bash
chmod +x .github/scripts/tfc-workspace-id.sh
```

- [ ] **Step 3: tfc-plan-comment.ymlを作成する**

```yaml
name: TFC Plan Comment

on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - "terraform/**"

permissions:
  contents: read
  pull-requests: write

jobs:
  plan-comment:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        include:
          - name: aws
            path: terraform/environments/personal/aws
            workspace: personal-aws
          - name: cloudflare
            path: terraform/environments/personal/cloudflare
            workspace: personal-cloudflare
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check for changes in workspace path
        id: changes
        run: |
          if git diff --name-only "${{ github.event.pull_request.base.sha }}" "${{ github.event.pull_request.head.sha }}" | grep -q "^${{ matrix.path }}/"; then
            echo "changed=true" >> "$GITHUB_OUTPUT"
          else
            echo "changed=false" >> "$GITHUB_OUTPUT"
          fi

      - name: Find TFC run
        if: steps.changes.outputs.changed == 'true'
        id: find
        env:
          TFC_TOKEN: ${{ secrets.TFC_TOKEN }}
        run: |
          ws_id=$(.github/scripts/tfc-workspace-id.sh disk0401 "${{ matrix.workspace }}")
          run_id=$(.github/scripts/tfc-find-run.sh "$ws_id" "${{ github.event.pull_request.head.sha }}" true)
          echo "run_id=$run_id" >> "$GITHUB_OUTPUT"

      - name: Wait for plan
        if: steps.changes.outputs.changed == 'true'
        env:
          TFC_TOKEN: ${{ secrets.TFC_TOKEN }}
        run: .github/scripts/tfc-poll-run.sh "${{ steps.find.outputs.run_id }}" 600

      - name: Build plan comment body
        if: steps.changes.outputs.changed == 'true'
        env:
          TFC_TOKEN: ${{ secrets.TFC_TOKEN }}
        run: |
          {
            echo '```'
            .github/scripts/tfc-get-plan-log.sh "${{ steps.find.outputs.run_id }}" | tail -c 60000
            echo '```'
            echo
            echo "[Terraform Cloudで詳細を見る](https://app.terraform.io/app/disk0401/workspaces/${{ matrix.workspace }}/runs/${{ steps.find.outputs.run_id }})"
          } > plan_body.md

      - name: Post comment
        if: steps.changes.outputs.changed == 'true'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          .github/scripts/post-pr-comment.sh "${{ github.event.pull_request.number }}" "<!-- tfc-plan:${{ matrix.name }} -->" plan_body.md
```

- [ ] **Step 4: コミットする**

```bash
git add .github/scripts/tfc-workspace-id.sh .github/workflows/tfc-plan-comment.yml
git commit -m "feat: PR作成時にTFC Planをコメントするワークフローを追加"
```

---

### Task 8: Applyコメントワークフローの作成

**Files:**
- Create: `.github/workflows/tfc-apply-comment.yml`

**Interfaces:**
- Consumes: `tfc-apply-and-report.sh`

- [ ] **Step 1: tfc-apply-comment.ymlを作成する**

```yaml
name: TFC Apply Comment

on:
  issue_comment:
    types: [created]

permissions:
  contents: read
  pull-requests: write
  issues: write

jobs:
  apply:
    if: |
      github.event.issue.pull_request != null &&
      github.event.comment.body == '/apply' &&
      github.event.comment.user.login == 'DISK0401'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Verify PR is merged
        id: pr
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          merged=$(gh api "repos/${{ github.repository }}/pulls/${{ github.event.issue.number }}" --jq '.merged')
          merge_sha=$(gh api "repos/${{ github.repository }}/pulls/${{ github.event.issue.number }}" --jq '.merge_commit_sha')
          if [ "$merged" != "true" ]; then
            gh api "repos/${{ github.repository }}/issues/${{ github.event.issue.number }}/comments" \
              -f body="このPRはまだmergeされていないため /apply は実行できません。" > /dev/null
            exit 1
          fi
          echo "merge_sha=$merge_sha" >> "$GITHUB_OUTPUT"

      - name: Determine changed workspaces
        id: changes
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          files=$(gh api "repos/${{ github.repository }}/pulls/${{ github.event.issue.number }}/files" --paginate --jq '.[].filename')
          aws_changed=false
          cf_changed=false
          if echo "$files" | grep -q "^terraform/environments/personal/aws/"; then aws_changed=true; fi
          if echo "$files" | grep -q "^terraform/environments/personal/cloudflare/"; then cf_changed=true; fi
          echo "aws_changed=$aws_changed" >> "$GITHUB_OUTPUT"
          echo "cf_changed=$cf_changed" >> "$GITHUB_OUTPUT"

      - name: Apply aws workspace
        if: steps.changes.outputs.aws_changed == 'true'
        env:
          TFC_TOKEN: ${{ secrets.TFC_TOKEN }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          .github/scripts/tfc-apply-and-report.sh \
            "personal-aws" \
            "${{ steps.pr.outputs.merge_sha }}" \
            "${{ github.event.issue.number }}" \
            "aws"

      - name: Apply cloudflare workspace
        if: steps.changes.outputs.cf_changed == 'true'
        env:
          TFC_TOKEN: ${{ secrets.TFC_TOKEN }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          .github/scripts/tfc-apply-and-report.sh \
            "personal-cloudflare" \
            "${{ steps.pr.outputs.merge_sha }}" \
            "${{ github.event.issue.number }}" \
            "cloudflare"
```

- [ ] **Step 2: コミットする**

```bash
git add .github/workflows/tfc-apply-comment.yml
git commit -m "feat: /applyコメントでTFC Applyを実行するワークフローを追加"
```

---

### Task 9: Terraform Cloudワークスペース設定の変更(人手)

**Files:** なし(Terraform Cloud UI上の操作)

- [ ] **Step 1: Auto ApplyをOFFにする**

`personal-aws`ワークスペースの Settings → General → Apply Method が `Manual apply` になっていることを確認する(`docs/superpowers/plans/2026-06-21-cloudflare-resource-import.md`のTask 3で`personal-cloudflare`と合わせて設定済みのはず。未設定なら両方とも`Manual apply`に変更する)。

- [ ] **Step 2: ブランチ保護を設定する(推奨)**

GitHub リポジトリ Settings → Branches → Add branch protection rule で、`main`ブランチへの直接pushを禁止し、PR経由のマージを必須にする。

---

### Task 10: READMEへの運用フロー追記

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 運用フローの説明を追記する**

`README.md`に以下の内容を追記する。

```markdown

## Terraformの運用フロー

1. `terraform/`配下を変更したブランチでPull Requestを作成する。
2. PR上にTerraform CloudのSpeculative Plan結果がコメントとして自動投稿される(`personal-aws`/`personal-cloudflare`で変更があったワークスペースごと)。内容を確認する。
3. レビュー後、PRを`main`にマージする。マージ時点ではまだapplyは実行されない(Terraform CloudのAuto ApplyはOFFになっている)。
4. マージ済みのPRに`/apply`とコメントすると、対応するワークスペースのRunが承認され、apply結果が完了後にPRコメントとして報告される。`/apply`はリポジトリオーナーのコメントのみ有効。
```

- [ ] **Step 2: コミットする**

```bash
git add README.md
git commit -m "docs: Terraformの運用フローをREADMEに追記"
```

---

### Task 11: エンドツーエンド動作確認

**Files:**
- Modify: 任意の小さな変更(例: `terraform/environments/personal/aws/acm.tf`へのコメント追加など、影響の小さいもの)

- [ ] **Step 1: 動作確認用の小さな変更でPRを作成する**

```bash
git checkout -b test/tfc-pr-workflow
# 影響の小さい変更を1箇所加える(例: タグの追記など)
git add -A
git commit -m "test: TFC PRワークフロー動作確認"
git push -u origin test/tfc-pr-workflow
```

GitHub上でPRを作成する。

- [ ] **Step 2: Planコメントを確認する**

PR上に`tfc-plan-comment.yml`のRunが実行され、対象ワークスペースのplan結果がコメントとして投稿されることを確認する。投稿されない場合、Actionsのログでエラー内容(Run検索失敗・認証エラー等)を確認し、該当スクリプトを修正する。

- [ ] **Step 3: PRをマージする**

PRをマージし、TFC上でRunが`Needs Confirmation`状態で停止していることをTFCダッシュボードで確認する。

- [ ] **Step 4: /applyコメントで承認する**

マージ済みPRに`/apply`とコメントする。`tfc-apply-comment.yml`が起動し、Applyの完了後に結果コメントが投稿されることを確認する。

- [ ] **Step 5: 動作確認用の変更を元に戻す**

動作確認のために加えた変更が不要であれば、別PRで元に戻す(同じフローで確認できる)。

---

## 完了条件

- `.github/scripts/`配下に本プランで作成した全スクリプトが存在し、`bash -n`での構文確認をすべて通過している。
- `.github/workflows/tfc-plan-comment.yml`・`tfc-apply-comment.yml`が存在し、Task 10のエンドツーエンド確認でPRコメントによるplan確認・apply実行・結果報告が一通り成功する。
- `personal-aws`・`personal-cloudflare`双方のTFCワークスペースでAuto ApplyがOFFになっている。
