# my_infra
Terraformでインフラ管理する

## Terraformの運用フロー

1. `terraform/`配下を変更したブランチでPull Requestを作成する。
2. PR上にTerraform CloudのSpeculative Plan結果がコメントとして自動投稿される(`personal-aws`/`personal-cloudflare`で変更があったワークスペースごと)。内容を確認する。
3. レビュー後、PRを`main`にマージする。マージ時点ではまだapplyは実行されない(Terraform CloudのAuto ApplyはOFFになっている)。
4. マージ済みのPRに`/apply`とコメントすると、対応するワークスペースのRunが承認され、apply結果が完了後にPRコメントとして報告される。`/apply`はリポジトリオーナーのコメントのみ有効。
