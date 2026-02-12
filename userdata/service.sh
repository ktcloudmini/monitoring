#terraform 사용예시
#시작 템플릿으로 만들 경우
# resource "aws_launch_template" "service" {
#   name_prefix = "service-"
#   # image_id, instance_type, vpc_security_group_ids, iam_instance_profile ...
#   user_data = base64encode(file("${path.module}/userdata/service.sh"))
# }
# resource "aws_instance" "service" {
#   count = 2

#   launch_template {
#     id      = aws_launch_template.service.id
#     version = "$Latest"
#   }

#   subnet_id = var.private_subnet_ids[count.index]
# }
#일반 인스턴스로 만들 경우
# resource "aws_instance" "service" {
#   count = 2
#   # ami, instance_type, subnet_id, vpc_security_group_ids ...
#   user_data = file("${path.module}/userdata/service.sh")
# }

#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

REGION="ap-northeast-2"
PARAM="/monitoring/github/pat"
REPO="ktcloudmini/monitoring"
DIR="/opt/monitoring"

ROLE="service"

apt-get update -y
apt-get install -y git curl awscli ca-certificates

apt-get install -y docker.io
systemctl enable --now docker
usermod -aG docker ubuntu || true

# (옵션) 태그 role=service
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
  sleep 3
done

set +x
GITHUB_PAT="$(aws ssm get-parameter --region "$REGION" --name "$PARAM" --with-decryption --query Parameter.Value --output text)"
rm -rf "$DIR" || true
git clone "https://${GITHUB_PAT}@github.com/${REPO}.git" "$DIR"
set -x

apt-get install -y python3 python3-pip
pip3 install --no-input ansible

cd "$DIR/ansible"
ansible-galaxy install -r requirements.yml

# 서비스 인스턴스: node_exporter + app(원하면)
ansible-playbook -i inventory/aws_ec2.yml playbooks/services.yml \
  -e target_role=service

echo "[DONE] service user-data finished"
