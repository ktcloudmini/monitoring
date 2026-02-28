# monitoring

AWS EC2 + ASG 환경에서 **Prometheus + Grafana 기반 모니터링 스택**을 운영하기 위한 레포지토리입니다.

- **Monitoring 인스턴스(단일 EC2)**: Prometheus + Grafana 컨테이너 실행
- **Service 인스턴스(태그: `role=asg`) / ASG 인스턴스들**
  - `node_exporter`로 Host metrics 노출
  - 서비스 팀이 제공하는 애플리케이션 `/metrics` 엔드포인트를 Prometheus가 스크랩
- Prometheus는 **EC2 Service Discovery(EC2 SD)** 로 대상 인스턴스를 자동 발견하고,
  EC2 태그 `role` 값을 Prometheus 라벨 `role`로 매핑합니다.

---

## What I'm building

- Host metrics 수집: `node_exporter` (CPU, Memory, Disk, Network 등)
- Application metrics 수집: 서비스 팀이 제공하는 `app.js`의 `/metrics`
- Prometheus 저장/쿼리
- Grafana 시각화
- Prometheus/Grafana 설정과 Grafana 대시보드를 이 레포에서 버전 관리

---

## Architecture (high-level)

- **Monitoring EC2**
  - Docker Compose로 Prometheus(:9090), Grafana(:3000) 실행
  - Prometheus EC2 SD로 VPC 내 인스턴스들을 자동 스크랩
- **Service EC2 / ASG EC2**
  - `node_exporter` :9100
  - 서비스 팀 제공 앱 메트릭 `/metrics` (예: :8080/metrics)

---

## Tag / Label Convention (중요)

EC2 태그 Key는 **`role` 또는 `Role`** 중 하나로 통일합니다.  
(아래 예시는 `role` 기준)

예시:

- `role=monitoring` (Prometheus/Grafana가 있는 서버)
- `role=asg` (서비스/ASG 대상 인스턴스들)

Prometheus는 EC2 SD 메타 라벨 `__meta_ec2_tag_role`을 사용해 아래 라벨을 붙입니다:

- `role="<tag value>"`
- `name="<EC2 Name tag>"` (선택)
- `instance="<EC2 instance-id>"` (선택)

> 태그 키를 `Role`(대문자 R)로 쓰면, Prometheus 설정의 메타 라벨도 `__meta_ec2_tag_Role`로 맞춰야 합니다.

---

## Directory Structure

- `docker-compose.yml` : Monitoring 인스턴스에서 Prometheus/Grafana 실행
- `prometheus/prometheus.yml` : EC2 SD + relabel 설정 (role 라벨 매핑 포함)
- `grafana/` : 프로비저닝(datasource/dashboard) + 대시보드 JSON

---

## Current status (verified)

- Monitoring 인스턴스 (Docker Compose)
  - Prometheus (:9090)
  - Grafana (:3000)

- Prometheus Targets 예시
  - `prometheus`: **UP**
  - `node`: **UP** (role=asg 대상, node_exporter)
  - `nodeapp`: **UP** (role=asg 대상, 앱 `/metrics`)

- Grafana
  - Prometheus datasource 연결
  - 대시보드에서 `instance`, `role` 라벨로 인스턴스별 시각화

---

## Prometheus Quick Checks

### 어떤 job이 스크랩되는지

Prometheus UI (Graph)에서:

```promql
count by (job) (up)

count by (role, job) (up)

rate(node_cpu_seconds_total[5m])

sum by (instance, route, status) (rate(http_requests_total[1m]))
