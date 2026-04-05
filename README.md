# zSafeGuard

zSafeGuard คือโปรเจกต์ตัวอย่างสำหรับระบบวิเคราะห์ความเสี่ยง (Risk Analysis) ที่ประกอบด้วย:
- **AI API** (FastAPI + โมเดล Ensemble)
- **Dashboard** (Next.js)
- **Deployment scripts** (Docker + Kubernetes + local orchestration)

เอกสารฉบับนี้เน้นการใช้งานบน GitHub และการเริ่มต้นใช้งานแบบครบวงจร

## โครงสร้างโปรเจกต์

```text
.
├── ai/
│   ├── main.py                # FastAPI app
│   ├── ensemble.py            # โหลด model และคำนวณ score
│   ├── model/                 # model files (xgb.pkl, nn.pkl)
│   └── requirements.txt       # Python dependencies
├── dashboard/
│   └── package.json           # Next.js dashboard
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── hpa.yaml
├── Dockerfile                 # build image ของ AI service
├── install.sh                 # basic install (dashboard deps)
├── install_full.sh            # basic + docker build
├── install_ultimate.sh        # full + minikube + kubectl apply
├── deploy.sh                  # local run + optional cloudflared
├── master-orchestrator.sh     # orchestration entrypoint
├── zlinebot-master-orchestrator.sh
└── codex.sh                   # mode-based runner (basic/full/...)
```

## ความสามารถหลัก

1. **API วิเคราะห์ความเสี่ยง**
   - Endpoint สำคัญ: `/`, `/health`, `/metrics`, `/analyze`
   - `/analyze` รับ `features` แล้วคืนค่า `score` และสถานะ `risk`

2. **โมเดล Ensemble**
   - ใช้ผลจาก `xgb` และ `nn`
   - สูตรคำนวณ: `score = xgb*0.6 + nn*0.4`
   - แปลผล:
     - `SAFE` เมื่อ score <= 0.5
     - `WARNING` เมื่อ 0.5 < score <= 0.75
     - `RISK` เมื่อ score > 0.75

3. **การ Deploy หลายระดับ**
   - ระดับ Basic / Full / Ultimate / Orchestrator / Release ผ่าน `codex.sh`

## ความต้องการระบบ

- Docker
- Node.js + npm
- Python 3.10+
- (แนะนำ) kubectl, minikube

## Quick Start

### 1) Clone และเข้าโฟลเดอร์

```bash
git clone <YOUR_REPO_URL>
cd zSafeGuard
```

### 2) รันแบบ Basic

```bash
bash codex.sh basic
```

### 3) รันแบบ Full

```bash
bash codex.sh full
```

### 4) รันแบบ Ultimate (ต้องมี kubectl)

```bash
bash codex.sh ultimate
```

### 5) รันแบบ Release workflow

```bash
bash codex.sh release
```

## การรันแบบ Local Dev (manual)

### AI service

```bash
pip install -r ai/requirements.txt
uvicorn ai.main:app --reload --host 0.0.0.0 --port 8000
```

### Dashboard

```bash
cd dashboard
npm install
npm run dev
```

## API ตัวอย่าง

### Health check

```bash
curl http://localhost:8000/health
```

### Analyze

```bash
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"features": [0.12, 0.8, 0.45, 0.19, 0.72]}'
```

ตัวอย่างผลลัพธ์:

```json
{
  "score": 0.63,
  "risk": "WARNING"
}
```

## การ Deploy ด้วย Kubernetes

```bash
kubectl apply -f k8s/
```

ไฟล์สำคัญ:
- `deployment.yaml`: replica + probe
- `service.yaml`: expose service port 80 -> 8000
- `ingress.yaml`: route HTTP path `/`
- `hpa.yaml`: autoscaling ตั้งแต่ 2 ถึง 10 replicas

## การใช้งานสคริปต์ `codex.sh`

```bash
bash codex.sh {basic|full|ultimate|orchestrator|release}
```

- `basic`: ติดตั้ง dashboard dependencies
- `full`: basic + docker build image
- `ultimate`: intended สำหรับขั้นสูง (ดู `install_ultimate.sh`)
- `orchestrator`: run master orchestrator
- `release`: full release workflow

บันทึก log ที่ `codex_release.log`

## GitHub Workflow (แนะนำ)

1. แตก branch ใหม่
2. แก้ไขโค้ด + เอกสาร
3. รันเช็คพื้นฐาน
   - `bash -n codex.sh`
   - `python -m py_compile ai/main.py ai/ensemble.py`
4. commit ด้วยข้อความชัดเจน
5. push + เปิด Pull Request

## ความปลอดภัยและข้อควรระวัง

- อย่า commit API key ลง repository
- ควรจำกัด `allow_origins` ของ CORS ใน production
- ตรวจสอบ image tag ให้ชัดเจนก่อน deploy
- ตรวจสอบว่ามีไฟล์ model ใน `ai/model/` ครบก่อนรัน API

## เอกสารเพิ่มเติม

อ่านคู่มือแบบละเอียดสำหรับ GitHub ได้ที่:
- [`docs/GITHUB_REPO_GUIDE_TH.md`](docs/GITHUB_REPO_GUIDE_TH.md)
