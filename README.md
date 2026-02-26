# monitoring

AWS EC2 + ASG 환경에서 **Prometheus + Grafana 기반 모니터링 스택**을 운영하기 위한 레포지토리입니다.

- **Monitoring 인스턴스(단일 EC2)**: Prometheus + Grafana 컨테이너 실행
- **Service / ASG 인스턴스들**: `node_exporter`(필수), (선택) Node.js 앱 메트릭 `/metrics`(`nodeapp`) 노출
- Prometheus는 **EC2 Service Discovery(EC2 SD)** 로 대상 인스턴스를 자동 발견하고,
  EC2 태그 `role` 값을 Prometheus 라벨 `role`로 매핑합니다.

---

## What I'm building

- Host metrics 수집: `node_exporter` (CPU, Memory, Disk, Network 등)
- Prometheus 저장/쿼리
- Grafana 시각화
- (선택) Node.js 샘플 앱 `/metrics` 노출 → Prometheus에서 `job=nodeapp`으로 스크랩
- 설정/대시보드/배포 코드(Ansible)까지 이 레포에서 버전 관리
- (추가 예정) GitHub Actions로 배포 자동화

---

## Architecture (high-level)

- **Monitoring EC2**
  - Docker Compose로 Prometheus(:9090), Grafana(:3000) 실행
  - Prometheus EC2 SD로 VPC 내 인스턴스들을 자동 스크랩
- **Service EC2 / ASG EC2**
  - `node_exporter` :9100 (필수)
  - (선택) Node.js 앱 :8080 + `/metrics` (필요할 때만)

---

## Tag / Label Convention (중요)

EC2 태그 Key는 **대소문자 `role or Role`** 로 통일합니다.

예시:
- `role=monitoring`  (Prometheus/Grafana가 있는 서버)
- `role=service`     (서비스 서버)
- `role=asg`         (ASG 인스턴스)

Prometheus는 EC2 SD 메타 라벨 `__meta_ec2_tag_role`을 사용해 아래 라벨을 붙입니다:
- `role="<tag value>"`
- `name="<EC2 Name tag>"` (선택)
- `instance="<EC2 instance-id>"` (선택)

---

## Directory Structure

- `docker-compose.yml` : Monitoring 인스턴스에서 Prometheus/Grafana 실행
- `prometheus/prometheus.yml` : EC2 SD + relabel 설정 (role 라벨 매핑 포함)
- `grafana/` : 대시보드/프로비저닝
- `ansible/`
  - `deploy_site.yml` : 전체 배포 진입점(노드 → 모니터링 순서)
  - `deploy_node.yml` : service/asg에 node_exporter (필요 시 nodeapp 포함)
  - `deploy_monitoring.yml` : monitoring에 Prometheus/Grafana
  - `aws_ec2.yml` : Ansible dynamic inventory (EC2 태그 기반 그룹핑)

---

## Current status (verified)

- Monitoring 인스턴스 (Docker Compose)
  - Prometheus (:9090)
  - Grafana (:3000)

- Prometheus Targets 예시
  - `prometheus`: **UP**
  - `node`: **UP** (service/asg 대상)
  - `nodeapp`: **UP** (service/asg 중 앱이 떠 있는 대상)

- Grafana
  - Prometheus datasource 연결
  - 대시보드에서 `instance`, `role` 라벨로 인스턴스별 시각화

---

## Prometheus Quick Checks

### 어떤 job이 스크랩되는지
Prometheus UI (Graph)에서:
```promql
count by (job) (up)
