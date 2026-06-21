# Cloudflareリソースimport Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cloudflare上の既存リソース(Zero Trust Tunnel、`disk0401.com`ゾーンのDNS)をTerraformの`personal-cloudflare`ワークスペースの管理下に取り込み、`terraform plan`が無差分(`No changes.`)になる状態にする。

**Architecture:** 新規`terraform/environments/personal/cloudflare/`配下にCloudflareプロバイダ(v5系)を設定し、`cf-terraforming`で既存リソースの定義(.tf)とimportコマンドを生成、既存ファイル命名規則に合わせて整形した上で`terraform import`によりTFCのリモートstateへ取り込む。

**Tech Stack:** Terraform `>= 1.8.0`、`cloudflare/cloudflare` provider `~> 5.21`、`cf-terraforming` CLI、Terraform Cloud(VCS駆動ワークスペース)。

## Global Constraints

- TFC organization: `disk0401`
- 新規ワークスペース名: `personal-cloudflare`、Terraform Working Directory: `terraform/environments/personal/cloudflare`
- プロバイダバージョン: `cloudflare/cloudflare ~> 5.21`(`versions.tf`に固定)
- ファイルはリソース種別/ドメインごとに1ファイルに分割する(既存`terraform/environments/personal/aws/`の命名規則を踏襲)
- 認証情報(`CLOUDFLARE_API_TOKEN`等)はリポジトリにコミットしない。TFCワークスペースのSensitive環境変数としてのみ保持する
- このリポジトリの既定ブランチは`main`(`master`ではない)

このプランは外部サービス(Cloudflare, Terraform Cloud)への手動操作と、ローカルでの認証情報入力を含む。該当ステップは「(人手)」と明記している。エージェントが実行する場合、その時点で作業を止めてユーザーに操作を依頼すること。

---

### Task 1: 前提ツールの確認

**Files:** なし(確認のみ)

- [ ] **Step 1: Terraform CLIの確認**

Run: `terraform version`
Expected: `Terraform v1.8.0`以上のバージョンが出力される。出力されない場合は[terraform.io](https://developer.hashicorp.com/terraform/install)の手順でインストールする。

- [ ] **Step 2: cf-terraformingの確認**

Run: `cf-terraforming --version`
Expected: バージョン文字列が出力される。出力されない場合はインストールし、PATHを通したうえで**ターミナル/エージェントセッションを再起動**してから再確認する。

---

### Task 2: Cloudflare APIトークンの発行(人手)

**Files:** なし(Cloudflareダッシュボード上の操作)

- [ ] **Step 1: APIトークンを発行する**

Cloudflareダッシュボード → My Profile → API Tokens → Create Token で、以下のスコープを持つトークンを発行する。

- `Zone / DNS / Edit`(対象ゾーン: `disk0401.com`)
- `Zone / Zone / Read`(対象ゾーン: `disk0401.com`)
- `Account / Cloudflare Tunnel / Edit`(対象アカウント: 該当アカウント)

- [ ] **Step 2: Account ID / Zone IDを控える**

Cloudflareダッシュボードのドメイン概要ページ右下に表示される`Account ID`と`Zone ID`(`disk0401.com`用)を控える。

- [ ] **Step 3: 値をローカル環境変数として一時的に設定する**

リポジトリにはコミットしないこと。シェルで以下を実行する(値は実際のものに置き換える)。

```bash
export CLOUDFLARE_API_TOKEN="<発行したトークン>"
export CLOUDFLARE_ACCOUNT_ID="<アカウントID>"
export CLOUDFLARE_ZONE_ID="<disk0401.comのゾーンID>"
```

---

### Task 3: Terraform Cloudワークスペースの作成(人手)

**Files:** なし(Terraform Cloud UI上の操作)

- [ ] **Step 1: ワークスペースを作成する**

Terraform Cloud(`https://app.terraform.io/app/disk0401`) → Workspaces → New workspace → Version control workflow → リポジトリ`DISK0401/my_infra`を選択し、以下を設定する。

- Workspace Name: `personal-cloudflare`
- Terraform Working Directory: `terraform/environments/personal/cloudflare`
- VCS branch: `main`

- [ ] **Step 2: 環境変数を設定する**

作成したワークスペースの Variables 画面で、Environment variable として以下を追加する(`CLOUDFLARE_API_TOKEN`は必ず"Sensitive"にチェックを入れる)。

- `CLOUDFLARE_API_TOKEN` = Task 2で発行したトークン (Sensitive)

- [ ] **Step 3: Auto ApplyをOFFにする**

`personal-cloudflare`ワークスペースの Settings → General → Apply Method を `Manual apply` に変更する。既存の`personal-aws`ワークスペースも同様に `Manual apply` に変更する。

- [ ] **Step 4: ローカルからTFCへログインする**

```bash
terraform login
```

ブラウザが開くのでTFCにログインし、表示されたAPIトークンをプロンプトに貼り付ける(`~/.terraform.d/credentials.tfrc.json`に保存される)。

---

### Task 4: プロバイダ雛形の追加

**Files:**
- Create: `terraform/environments/personal/cloudflare/versions.tf`
- Create: `terraform/environments/personal/cloudflare/main.tf`
- Create: `terraform/environments/personal/cloudflare/variables.tf`

- [ ] **Step 1: versions.tfを作成する**

```hcl
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.21"
    }
  }

  cloud {
    organization = "disk0401"
    workspaces {
      name = "personal-cloudflare"
    }
  }
}
```

- [ ] **Step 2: main.tfを作成する**

```hcl
provider "cloudflare" {}
```

- [ ] **Step 3: variables.tfを作成する**

```hcl
#################################################
# Cloudflare固有変数
#################################################

variable "cloudflare_account_id" {
  description = "CloudflareアカウントID"
  type        = string
}
```

- [ ] **Step 4: terraform initを実行する**

```bash
cd terraform/environments/personal/cloudflare
terraform init
```

Expected: `Terraform Cloud has been successfully initialized!`が出力される。

- [ ] **Step 5: コミットする**

```bash
git add terraform/environments/personal/cloudflare/versions.tf terraform/environments/personal/cloudflare/main.tf terraform/environments/personal/cloudflare/variables.tf
git commit -m "feat: Cloudflareプロバイダの雛形を追加"
```

---

### Task 5: cf-terraformingでリソース定義とimportコマンドを生成する

**Files:**
- Create(一時ファイル、最終的にコミットしない): `tmp_generated_tunnel.tf`, `tmp_generated_zone.tf`, `tmp_import_tunnel.sh`, `tmp_import_zone.sh`

- [ ] **Step 1: アカウントレベルのリソース(Zero Trust Tunnel)を生成する**

```bash
cd terraform/environments/personal/cloudflare
cf-terraforming generate \
  --resource-type "cloudflare_zero_trust_tunnel_cloudflared" \
  --account "$CLOUDFLARE_ACCOUNT_ID" \
  > tmp_generated_tunnel.tf

cf-terraforming import \
  --resource-type "cloudflare_zero_trust_tunnel_cloudflared" \
  --account "$CLOUDFLARE_ACCOUNT_ID" \
  > tmp_import_tunnel.sh
```

Expected: `tmp_generated_tunnel.tf`に検出された`cloudflare_zero_trust_tunnel_cloudflared`リソースのHCL定義が、`tmp_import_tunnel.sh`に対応する`terraform import`コマンド一覧が出力される。

- [ ] **Step 2: ゾーンレベルのリソース(DNS)を生成する**

```bash
cf-terraforming generate \
  --resource-type "cloudflare_zone,cloudflare_dns_record" \
  --zone "$CLOUDFLARE_ZONE_ID" \
  > tmp_generated_zone.tf

cf-terraforming import \
  --resource-type "cloudflare_zone,cloudflare_dns_record" \
  --zone "$CLOUDFLARE_ZONE_ID" \
  > tmp_import_zone.sh
```

Expected: `tmp_generated_zone.tf`に`cloudflare_zone`・`cloudflare_dns_record`のHCL定義が、`tmp_import_zone.sh`に対応する`terraform import`コマンド一覧が出力される。

- [ ] **Step 3: 出力内容を確認する**

```bash
cat tmp_generated_tunnel.tf
cat tmp_generated_zone.tf
```

検出されたリソース数と内容(Tunnel名、DNSレコードのname/type/content)が、Cloudflareダッシュボード上の実際の設定と一致することを目視で確認する。一致しない場合、`--resource-type`の指定や`cf-terraforming --help`で利用可能なリソースタイプを再確認する。

---

### Task 6: 生成内容を命名規則に沿って整形する

**Files:**
- Create: `terraform/environments/personal/cloudflare/zero_trust_tunnel.tf`
- Create: `terraform/environments/personal/cloudflare/zone_disk0401_com.tf`

- [ ] **Step 1: zero_trust_tunnel.tfを作成する**

`tmp_generated_tunnel.tf`の内容を元に、以下の形式で`zero_trust_tunnel.tf`を作成する(実際のTunnel名・IDはTask 5の出力に置き換える。例として1つのTunnelがある場合):

```hcl
resource "cloudflare_zero_trust_tunnel_cloudflared" "<tunnel_name>" {
  account_id = var.cloudflare_account_id
  name       = "<実際のTunnel名>"
  # cf-terraformingが生成した残りの属性(config_src等)をそのまま転記する
}
```

`tmp_generated_tunnel.tf`に出力された属性をすべて転記すること(省略しない)。`account_id`は`var.cloudflare_account_id`参照に置き換える。

- [ ] **Step 2: zone_disk0401_com.tfを作成する**

`tmp_generated_zone.tf`の内容を元に、既存`terraform/environments/personal/aws/dns_disk0401_net.tf`のスタイル(ゾーン定義の後にレコードを列挙)に合わせて作成する:

```hcl
resource "cloudflare_zone" "disk0401_com" {
  account = {
    id = var.cloudflare_account_id
  }
  name = "disk0401.com"
}

# 以降、tmp_generated_zone.tfに出力された各cloudflare_dns_recordリソースを
# zone_id = cloudflare_zone.disk0401_com.id を参照する形に書き換えて列挙する
```

`tmp_generated_zone.tf`内の各レコードのリソース名は、`disk0401_com_<サブドメイン>_<type>`のように既存AWS側の命名規則(`disk0401_net_disk0401_net_a`等)に揃える。

- [ ] **Step 3: terraform validateで構文確認する**

```bash
cd terraform/environments/personal/cloudflare
terraform validate
```

Expected: `Success! The configuration is valid.`

- [ ] **Step 4: 一時生成ファイルを削除する**

```bash
rm -f tmp_generated_tunnel.tf tmp_generated_zone.tf
```

(`tmp_import_tunnel.sh` / `tmp_import_zone.sh`はTask 7で使うため、このタスクでは削除しない。)

---

### Task 7: terraform importでTFCのstateに取り込む

**Files:** なし(state操作のみ)

- [ ] **Step 1: Tunnelをimportする**

```bash
cd terraform/environments/personal/cloudflare
bash tmp_import_tunnel.sh
```

`tmp_import_tunnel.sh`内の各`terraform import <生成されたリソースアドレス> <ID>`が、Task 6で書き換えた`zero_trust_tunnel.tf`内の実際のリソースアドレスと一致しない場合は、コマンド中のアドレス部分を書き換えてから実行する。

Expected: 各importコマンドが`Import successful!`を出力する。

- [ ] **Step 2: ゾーン・DNSレコードをimportする**

```bash
bash tmp_import_zone.sh
```

同様に、リソースアドレスをTask 6で命名した内容に合わせて書き換えてから実行する。

Expected: 各importコマンドが`Import successful!`を出力する。

- [ ] **Step 3: 一時importスクリプトを削除する**

```bash
rm -f tmp_import_tunnel.sh tmp_import_zone.sh
```

---

### Task 8: 差分ゼロを確認してコミットする

**Files:**
- Modify: `terraform/environments/personal/cloudflare/zero_trust_tunnel.tf`
- Modify: `terraform/environments/personal/cloudflare/zone_disk0401_com.tf`

- [ ] **Step 1: terraform planを実行する**

```bash
cd terraform/environments/personal/cloudflare
terraform plan
```

Expected: `No changes. Your infrastructure matches the configuration.`

差分がある場合は、表示された差分の内容(属性名・値)を`zero_trust_tunnel.tf`/`zone_disk0401_com.tf`に反映し、差分がゼロになるまでStep 1を繰り返す。

- [ ] **Step 2: コミットする**

```bash
git add terraform/environments/personal/cloudflare/zero_trust_tunnel.tf terraform/environments/personal/cloudflare/zone_disk0401_com.tf
git commit -m "import: Cloudflare Zero Trust TunnelとDNSレコード"
```

- [ ] **Step 3: 不要な一時ファイルが残っていないことを確認する**

```bash
git status
```

Expected: `tmp_`で始まるファイルが作業ツリーに存在しない(`Untracked files`に出てこない)。

---

## 完了条件

- `terraform/environments/personal/cloudflare/`配下に`versions.tf`, `main.tf`, `variables.tf`, `zero_trust_tunnel.tf`, `zone_disk0401_com.tf`が存在する。
- `terraform plan`が`No changes.`を返す。
- Cloudflareの認証情報がリポジトリ内のどのファイルにも含まれていない。
