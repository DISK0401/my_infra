#!/usr/bin/env bash
set -euo pipefail
# disk0401.net の white-label NS (ns1-4.disk0401.net) は、Route53が割り当てた
# awsdns-* ネームサーバーのIPをglueとしてレジストラに固定登録している。
# AWS側のIPが変わるとglueが古くなり名前解決が壊れるため、
# (1) .net TLDのglue (2) ゾーン内のA/AAAA (3) awsdns-*の実IP が一致するか検証する。
# 対応表は terraform/environments/personal/aws/dns_disk0401_net_nameservers.tf と揃えること。

domain="disk0401.net"
tld_server="a.gtld-servers.net"
declare -A backing=(
  [ns1]="ns-481.awsdns-60.com"
  [ns2]="ns-788.awsdns-34.net"
  [ns3]="ns-1041.awsdns-02.org"
  [ns4]="ns-1755.awsdns-27.co.uk"
)

referral=$(dig +norec +noall +authority +additional "@${tld_server}" "$domain" NS)

delegated=$(awk '$4 == "NS" {print $5}' <<<"$referral" | sed 's/\.$//' | sort)
expected=$(for k in "${!backing[@]}"; do echo "${k}.${domain}"; done | sort)
failed=0

if [ "$delegated" != "$expected" ]; then
  echo "::error::.net TLDの委任先が想定と異なります: $(echo $delegated)"
  failed=1
fi

for ns in "${!backing[@]}"; do
  host="${ns}.${domain}"
  for type in A AAAA; do
    actual=$(dig +short "${backing[$ns]}" "$type" | sort)
    glue=$(awk -v h="${host}." -v t="$type" '$1 == h && $4 == t {print $5}' <<<"$referral" | sort)
    zone=$(dig +short "@${backing[$ns]}" "$host" "$type" | sort)
    if [ -z "$actual" ] || [ "$glue" != "$actual" ] || [ "$zone" != "$actual" ]; then
      echo "::error::${host} ${type} 不一致: glue=[$(echo $glue)] zone=[$(echo $zone)] ${backing[$ns]}=[$(echo $actual)]"
      failed=1
    else
      echo "ok: ${host} ${type} ${actual}"
    fi
  done
done

exit "$failed"
