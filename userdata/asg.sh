#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

PARAM="/monitoring/github/pat"
REPO="ktcloudmini/monitoring"
DIR="/opt/monitoring"

IMDS="http://169.254.169.254/latest"
TOKEN="$(curl -sS -X PUT "$IMDS/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)"
HDR=()
if [ -n "${TOKEN:-}" ]; then HDR=(-H "X-aws-ec2-metadata-token: $TOKEN"); fi

REGION="$(curl -sS "${HDR[@]}" "$IMDS/meta-data/placement/region" || true)"
REGION="${REGION:-ap-northeast-2}"
INSTANCE_ID="$(curl -sS "${HDR[@]}" "$IMDS/meta-data/instance-id")"

apt-get update -y
apt-get install -y git curl awscli ca-certificates docker.io docker-compose-plugin

systemctl enable --now docker
usermod -aG docker ubuntu || true

# (선택) role 태깅을 user-data에서 하고 싶을 때만
for i in {1..10}; do
  if aws ec2 create-tags --region "$REGION" --resources "$INSTANCE_ID" --tags "Key=role,Value=asg"; then
    echo "[OK] tagged role=asg"
    break
  fi
  echo "[WARN] tagging failed (attempt $i). retry in 3s..."
  sleep 3
done

set +x
GITHUB_PAT="$(aws ssm get-parameter --region "$REGION" --name "$PARAM" --with-decryption --query Parameter.Value --output text)"
rm -rf "$DIR" || true
git clone "https://${GITHUB_PAT}@github.com/${REPO}.git" "$DIR"
set -x

chown -R ubuntu:ubuntu "$DIR"
cd "$DIR"

# ASG = app + node_exporter
docker compose --profile app --profile node up -d --build

echo "[DONE] asg user-data finished"
