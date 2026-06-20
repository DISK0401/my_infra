# Cloudflare管理の追加 と Terraform CloudのPRベース運用への移行

## 背景・目的

- 現在AWS環境はTerraform Cloud(TFC)の`personal-aws`ワークスペース(VCS駆動)で管理しており、`main`ブランチへのpushで自動的にplan→applyまで実行される。
- Cloudflareは現在Terraform管理外で、Zero Trust/Tunnelと`disk0401.com`ドメインを少なくとも利用している(他にも利用中のリソースがある可能性があり、全容は未把握)。
- 今回、以下2点を実現する。
  1. Cloudflare上の既存リソースをTerraformで管理できるようにする(import含む)。
  2. TFCの運用を「pushで自動apply」から「PRでplanを確認し、マージ後に明示的な承認を経てapplyする」フローに変更する。承認はGitHub PRコメント(`/apply`)から行えるようにする。

## スコープ外

- Cloudflareの新規リソース設計・追加(まずは既存リソースの取り込みのみ)。
- `personal-aws`ワークスペースのリソース構成自体の変更(ワークフロー変更のみ対象)。
- GCP環境(`terraform/environments/personal/gcp/`は現状未使用のまま)。

---

## セクション1: Cloudflareリソース管理

### ワークスペース構成

- 新規TFCワークスペース `personal-cloudflare` を作成する(VCS駆動、Working Directory: `terraform/environments/personal/cloudflare`)。
- アカウントレベル(Zero Trust/Tunnel等)とゾーンレベル(`disk0401.com`のDNS等)を**ワークスペースは分けず、ファイル名で区別**する。既存`aws/`ディレクトリと同じフラット構成・命名規則を踏襲する。
  - `versions.tf` / `main.tf` / `variables.tf`: 共通設定(プロバイダ・TFC連携)
  - `zero_trust_tunnel.tf`: アカウントレベルのZero Trust/Tunnel関連リソース
  - `zone_disk0401_com.tf`: `disk0401.com`ゾーン本体とDNSレコード
  - 今後Cloudflare上のドメインが増えた場合は `zone_<domain>.tf` を追加するだけでよい
- 既に別ブランチ(`claude/cloudflare-management-transition-3052yj`)に以下の雛形が存在するため、これをベースに進める。
  - `versions.tf`: `cloudflare/cloudflare`プロバイダ `~> 5.21`、`cloud`ブロックで`personal-cloudflare`ワークスペースを参照
  - `variables.tf`: `cloudflare_account_id`変数を定義済み
  - `main.tf`: `provider "cloudflare" {}` (空)
- Cloudflareプロバイダv5系は命名が刷新されている(例: `cloudflare_record` → `cloudflare_dns_record`、Tunnelは`cloudflare_zero_trust_tunnel_cloudflared`等)。生成・記述時はv5系のリソース名に従う。

### 認証情報

- `CLOUDFLARE_API_TOKEN`は**TFCワークスペースのSensitive環境変数**として設定し、リポジトリには含めない(`*.tfvars`は既に`.gitignore`対象)。
- Terraformでの継続運用(plan/apply)にはDNS/Tunnel等の対象リソースへの**Edit権限を含むトークン**が必要(Read権限のみでは差分管理ができない)。

### 既存リソースの洗い出し・import手順

1. Cloudflareダッシュボードで対象リソースを管理可能なAPIトークンを発行する(スコープ: Zone:DNS:Edit, Zone:Zone:Read, Account:Cloudflare Tunnel:Edit、対象は`disk0401.com`ゾーンおよび該当アカウント)。
2. `cf-terraforming`(ローカルにインストール済み)を使い、`generate`サブコマンドでリソース定義(.tf)を、`import`サブコマンドで対応する`terraform import`コマンド一覧を生成する。対象リソースタイプは実装時に`cf-terraforming --help`で確認し、少なくとも`cloudflare_zone`, `cloudflare_dns_record`, `cloudflare_zero_trust_tunnel_cloudflared`を含める。
3. 生成結果を確認しながら、上記のファイル命名規則に沿って`zero_trust_tunnel.tf` / `zone_disk0401_com.tf`に整形する(機械生成そのままでなく、既存ファイルのスタイル — リソース名・コメント等 — に合わせる)。
4. `terraform import`をTFCワークスペースに対して実行し、リモートstateに取り込む(これまでのAWSリソースimportと同じやり方)。
5. `terraform plan`を実行し、差分がゼロであることを確認してからコミットする。
6. cf-terraformingで拾いきれない・未把握のリソースがあれば、Cloudflareダッシュボードで都度確認しながら追加対応する(今回のスコープでは「分かっているものを取り込む」ことを優先し、完全な棚卸しは将来的な継続タスクとする)。

---

## セクション2: PRベースのApplyフロー

### Terraform Cloud側の設定変更(手動、UI上で1回実施)

- `personal-aws`・`personal-cloudflare`の両ワークスペースで **Auto Apply を OFF** にする。
  - これにより、`main`へのマージ後もRunは「Needs Confirmation」状態で止まり、明示的な承認が行われるまでapplyされない。
- PRに対するSpeculative Plan自動実行は、VCS連携ワークスペースのデフォルト動作のため変更不要。

### GitHub Actions ワークフロー

1. **`.github/workflows/tfc-plan-comment.yml`**
   - トリガー: `pull_request`(opened, synchronize, reopened)、`terraform/**`に変更がある場合のみ。
   - 変更パスから対象ワークスペース(`aws` / `cloudflare`)を判定する。
   - 各対象ワークスペースについて、PRのHEAD commit SHAに対応するTFCのSpeculative Runを検索し、完了をポーリングで待つ。
   - plan本文を取得し、PRコメントとして投稿する。再実行時は新規コメントを増やさず、既存コメントを更新する。

2. **`.github/workflows/tfc-apply-comment.yml`**
   - トリガー: `issue_comment`(created)で、コメント本文が`/apply`、かつ対象PRが**マージ済み**であること。
   - **認可チェック**: コメント投稿者がリポジトリオーナー(`DISK0401`)であることを確認する。本リポジトリはPublicであり、それ以外のユーザーからのコメントでは何もせず拒否のリアクション/返信のみ行う。
   - マージコミットSHAに対応する、対象ワークスペースの「承認待ちRun」をTFC APIで検索する。
   - 該当Runに対してApply確認APIを呼び出し、完了をポーリングで待つ。
   - 完了後、結果(成功/失敗、変更リソース数、TFCのRunへのリンク)をPRコメントで報告する。

3. 上記2ワークフローで共通するTFC API操作(commit SHAからRunを特定、ポーリング、ログ取得、PRコメントの投稿・更新)は`.github/scripts/`配下のスクリプトに切り出し、共用する。

### Secrets

- `TFC_TOKEN`: 対象ワークスペースに対してRunの管理(confirm含む)権限を持つTFCのTeam API Tokenを発行し、GitHub Secretsの`TFC_TOKEN`として登録する。

### ブランチ運用

- 現状`main`ブランチに直接pushしても動作してしまうため、GitHub側のブランチ保護ルールで`main`への直接pushを禁止し、PR経由を必須にすることを推奨する(必須要件ではないが、フロー変更の実効性を担保するために併せて設定する)。

---

## 手動セットアップ手順(実装と並行してユーザー側で実施)

実装(Terraformコード・GitHub Actionsワークフローの作成)は別途進めるが、以下はTerraform外で必要な手動操作であり、実装の前提として必要なタイミングで実施する。

### A. Cloudflare

1. Cloudflareダッシュボード → My Profile → API Tokens → Create Token。
   - スコープ: Zone:DNS:Edit, Zone:Zone:Read(対象: `disk0401.com`)、Account:Cloudflare Tunnel:Edit(対象: 該当アカウント)。
   - 発行したトークンとAccount ID(ダッシュボード右下に表示)を控える。

### B. Terraform Cloud

1. Organization `disk0401`に新規ワークスペースを作成する。
   - Version control workflow → GitHubリポジトリ`DISK0401/my_infra`を選択。
   - Workspace名: `personal-cloudflare`。
   - Terraform Working Directory: `terraform/environments/personal/cloudflare`。
   - VCS branch: `main`。
2. ワークスペースの環境変数に`CLOUDFLARE_API_TOKEN`(Sensitive)を設定する(Aで発行したトークン)。
3. `personal-cloudflare`・`personal-aws`双方のワークスペース設定で **Auto Apply をOFF** にする。
4. Run確認(Apply)権限を持つTeam API Tokenを発行する(Organization Settings → Teams → 該当チーム → Team API Token、またはユーザーAPIトークン)。

### C. GitHub

1. リポジトリ Settings → Secrets and variables → Actions → New repository secret。
   - `TFC_TOKEN`: Bで発行したTFCのAPIトークン。
2. (推奨) Settings → Branches → `main`への直接pushを禁止し、PR必須のルールを追加する。

### D. 実装側(このタスクで対応する範囲)

1. `claude/cloudflare-management-transition-3052yj`にある雛形(`versions.tf`/`main.tf`/`variables.tf`)を取り込み、`zero_trust_tunnel.tf`・`zone_disk0401_com.tf`等を追加する。
2. `cf-terraforming`の出力を元に、Cloudflareリソースを`terraform import`でTFCのstateに取り込み、`terraform plan`で差分ゼロを確認する。
3. `.github/workflows/tfc-plan-comment.yml`、`.github/workflows/tfc-apply-comment.yml`、`.github/scripts/`のスクリプト一式を実装する。
4. READMEに新しい運用フロー(PRでplanコメント確認 → マージ → `/apply`コメントでapply)を追記する。

---

## テスト方針

- ワークフローの動作確認は、影響の小さい変更(例: タグの追加など)でPRを作成し、実際にplanコメント投稿 → マージ → `/apply`コメント → applyコメント投稿までの一連の流れを通しで確認する。
- 認可チェック(オーナー以外のコメントを無視すること)も、可能であれば別アカウントまたはコメント内容のシミュレーションで確認する。
- Cloudflareリソースのimportについては、`terraform plan`で差分ゼロになることを必須の完了条件とする。
