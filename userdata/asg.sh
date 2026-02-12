#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

REGION="ap-northeast-2"
PARAM="/monitoring/github/pat"
REPO="ktcloudmini/monitoring"     # 너 레포
DIR="/opt/monitoring"             # checkout 위치

ROLE="asg"

apt-get update -y
apt-get install -y git curl awscli ca-certificates

# docker
apt-get install -y docker.io
systemctl enable --now docker
usermod -aG docker ubuntu || true

# (옵션) 인스턴스 태그 role=asg
IMDS="http://169.254.169.254/latest"
TOKEN="$(curl -sS -X PUT "$IMDS/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)"
if [ -n "${TOKEN:-}" ]; then HDR=(-H "X-aws-ec2-metadata-token: $TOKEN"); else HDR=(); fi
INSTANCE_ID="$(curl -sS "${HDR[@]}" "$IMDS/meta-data/instance-id")"
REGION_META="$(curl -sS "${HDR[@]}" "$IMDS/meta-data/placement/region" || true)"
if [ -n "${REGION_META:-}" ]; then REGION="$REGION_META"; fi

for i in {1..10}; do
  if aws ec2 create-tags --region "$REGION" --resources "$INSTANCE_ID" --tags "Key=role,Value=${ROLE}"; then
    echo "[OK] tagged instance $INSTANCE_ID: role=${ROLE}"
    break
  fi
  echo "[WARN] tagging failed (attempt $i). retry in 3s..."
  sleep 3
done

# repo clone (PAT은 로그에 안 찍히게)
set +x
GITHUB_PAT="$(aws ssm get-parameter \
  --region "$REGION" --name "$PARAM" --with-decryption \
  --query Parameter.Value --output text)"
rm -rf "$DIR" || true
git clone "https://${GITHUB_PAT}@github.com/${REPO}.git" "$DIR"
set -x

# ansible 실행 준비
apt-get install -y python3 python3-pip
pip3 install --no-input ansible

cd "$DIR/ansible"
ansible-galaxy install -r requirements.yml

# ASG는 node_exporter + app(필요 시)만
ansible-playbook -i inventory/aws_ec2.yml playbooks/services.yml \
  -e target_role=asg

echo "[DONE] ASG user-data finished"
