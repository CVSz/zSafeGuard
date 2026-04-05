# คู่มือและข้อมูล Repository (ฉบับละเอียด) สำหรับใช้งานบน GitHub

เอกสารนี้จัดทำเพื่ออธิบาย repo `zSafeGuard` แบบละเอียด ครอบคลุมสถาปัตยกรรม การทำงานของแต่ละโมดูล วิธีรัน การ deploy แนวทาง contribution และ checklist ก่อนขึ้น production

---

## 1) ภาพรวมระบบ

`zSafeGuard` เป็นระบบต้นแบบสำหรับวิเคราะห์ระดับความเสี่ยงจากข้อมูลเชิงตัวเลข (`features`) โดยมีองค์ประกอบหลักดังนี้

- **AI Backend**: FastAPI ให้บริการ endpoint สำหรับ health, metrics และ inference
- **Model Layer**: Ensemble ของโมเดล XGBoost + Neural Network
- **Dashboard**: ส่วน frontend (Next.js) สำหรับใช้งาน/แสดงผล
- **Ops Layer**: Dockerfile, Kubernetes manifests, และ shell scripts สำหรับ install/deploy

แนวคิดการไหลของข้อมูล:
1. Client ส่งข้อมูลเข้า `/analyze`
2. Backend เรียก `predict(features)`
3. โมเดลรวมคะแนนแล้ว map เป็นระดับความเสี่ยง
4. ส่ง JSON response กลับไปยัง client

---

## 2) โครงสร้างไฟล์และความรับผิดชอบ

### 2.1 โฟลเดอร์ `ai/`

- `main.py`
  - สร้าง FastAPI app
  - ตั้งค่า CORS middleware
  - endpoint:
    - `GET /` สถานะทั่วไป
    - `GET /health` สำหรับ readiness/liveness probe
    - `GET /metrics` metadata พื้นฐานของ service
    - `POST /analyze` รับ payload แล้วคืนผลวิเคราะห์
- `ensemble.py`
  - โหลดโมเดลจาก `ai/model/`
  - คำนวณคะแนนสุดท้ายด้วย weighted average
  - แปลงคะแนนเป็น label `SAFE/WARNING/RISK`
- `requirements.txt`
  - dependencies ฝั่ง Python

### 2.2 โฟลเดอร์ `dashboard/`

- `package.json`
  - ระบุ dependencies หลัก: `next`, `react`, `react-dom`
  - scripts:
    - `npm run dev`
    - `npm start` (ในโปรเจกต์นี้ mapped ไป `next dev` เช่นกัน)

### 2.3 โฟลเดอร์ `k8s/`

- `deployment.yaml`
  - Deployment ชื่อ `ai-service`
  - replicas=2
  - readiness/liveness probe เรียก `/health`
- `service.yaml`
  - Service ชื่อ `ai-service`
  - expose port 80 ไป targetPort 8000
- `ingress.yaml`
  - กำหนด HTTP routing path `/`
- `hpa.yaml`
  - HorizontalPodAutoscaler ขั้นพื้นฐาน
  - min 2, max 10 replicas

### 2.4 ไฟล์ orchestration/deployment script

- `install.sh`
  - ติดตั้ง dependencies ฝั่ง dashboard (`npm install`)
- `install_full.sh`
  - เรียก `install.sh`
  - build Docker image (`zsafe-ai`)
- `install_ultimate.sh`
  - เรียก `install_full.sh`
  - start minikube (ถ้ามี)
  - apply manifests ใน `k8s/`
- `deploy.sh`
  - build image
  - optional: minikube + kubectl apply
  - start `uvicorn` และ dashboard พร้อมกัน
  - ถ้ามี cloudflared จะเปิด tunnel
- `master-orchestrator.sh`
  - เรียก `zlinebot-master-orchestrator.sh`
- `zlinebot-master-orchestrator.sh`
  - wrapper script ที่เรียก `deploy.sh`
- `codex.sh`
  - script หลักสำหรับเลือกโหมดการติดตั้ง/ปล่อยระบบ

---

## 3) พฤติกรรม AI Inference

ใน `ensemble.py`:
- `xgb.predict_proba([features])[0][1]` -> ความน่าจะเป็นฝั่ง positive class
- `nn.predict([features])[0]` -> ค่าคาดการณ์ของ neural model
- ค่ารวม: `score = x*0.6 + n*0.4`

กติกาการตีความ score:
- `score <= 0.5` -> `SAFE`
- `0.5 < score <= 0.75` -> `WARNING`
- `score > 0.75` -> `RISK`

> หมายเหตุ: ควรกำหนด schema ของ `features` ให้ชัดเจนในระดับ API contract เช่น จำนวนมิติและช่วงค่า เพื่อป้องกัน input mismatch

---

## 4) วิธีใช้งานสำหรับผู้ใช้ GitHub

### 4.1 การ Clone

```bash
git clone <repo-url>
cd zSafeGuard
```

### 4.2 การรันตาม mode

```bash
bash codex.sh basic
bash codex.sh full
bash codex.sh ultimate
bash codex.sh orchestrator
bash codex.sh release
```

### 4.3 รันแบบแยกส่วน

AI API:
```bash
pip install -r ai/requirements.txt
uvicorn ai.main:app --reload
```

Dashboard:
```bash
cd dashboard
npm install
npm run dev
```

---

## 5) การใช้งาน API (ตัวอย่าง)

### 5.1 ตรวจสอบสถานะ

```bash
curl http://localhost:8000/
curl http://localhost:8000/health
curl http://localhost:8000/metrics
```

### 5.2 วิเคราะห์ความเสี่ยง

```bash
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{"features": [0.1, 0.2, 0.3, 0.4, 0.5]}'
```

ผลลัพธ์ที่คาดหวัง:

```json
{
  "score": 0.0,
  "risk": "SAFE"
}
```

(ค่า score จริงขึ้นกับโมเดลและข้อมูล input)

---

## 6) แนวทางตั้งค่า Production

1. **CORS hardening**
   - จำกัด `allow_origins` ตามโดเมนจริง
2. **Secret management**
   - เก็บ `API_KEY` ผ่าน Kubernetes Secret หรือ Secret Manager
3. **Image strategy**
   - ใช้ tag แบบ immutable (`zsafe-ai:<git-sha>`)
4. **Observability**
   - เพิ่ม structured logging, request id, metrics จริง (Prometheus format)
5. **Model governance**
   - versioning ของ model files
   - เพิ่ม validation ก่อนโหลดโมเดล
6. **Reliability**
   - เพิ่ม resource requests/limits ใน Deployment
   - ขยาย HPA ด้วย target CPU/Memory metrics

---

## 7) แนวทางสำหรับผู้ร่วมพัฒนา (Contributors)

### 7.1 Branching
- ใช้ `feature/<name>` สำหรับฟีเจอร์ใหม่
- ใช้ `fix/<name>` สำหรับแก้ bug
- เปิด PR พร้อมคำอธิบายผลกระทบ

### 7.2 Commit Message (แนะนำ)
- `docs: add detailed Thai GitHub repository guide`
- `feat(ai): add input schema validation`
- `fix(deploy): handle missing kubectl gracefully`

### 7.3 ตรวจสอบก่อน PR

```bash
bash -n codex.sh
bash -n deploy.sh
python -m py_compile ai/main.py ai/ensemble.py
```

---

## 8) Release Checklist

- [ ] API endpoint ทำงานครบ
- [ ] Dashboard รันได้
- [ ] Docker image build ผ่าน
- [ ] Kubernetes manifests apply ผ่าน
- [ ] เอกสาร README อัปเดต
- [ ] Security review เบื้องต้นผ่าน
- [ ] มี rollback plan

---

## 9) ปัญหาที่พบบ่อย (Troubleshooting)

1. **โมเดลโหลดไม่ขึ้น**
   - ตรวจสอบว่ามีไฟล์ `ai/model/xgb.pkl` และ `ai/model/nn.pkl`
2. **kubectl apply ไม่ผ่าน**
   - ตรวจ context และสิทธิ์คลัสเตอร์
3. **Dashboard เปิดไม่ขึ้น**
   - ลบ `node_modules` แล้ว `npm install` ใหม่
4. **Docker build fail**
   - เช็ค network/proxy และเวอร์ชัน Docker

---

## 10) แนวทางปรับปรุงต่อ

- เพิ่ม OpenAPI schema และ request validation (Pydantic models)
- เพิ่มชุดทดสอบ unit/integration
- เพิ่ม GitHub Actions สำหรับ CI/CD
- เพิ่ม documentation ฝั่งสถาปัตยกรรม (C4 model)
- เพิ่ม load test และ performance baseline

---

หากต้องการให้เอกสารนี้แยกเป็นภาษาอังกฤษ/ไทยคู่กัน แนะนำเพิ่มไฟล์:
- `docs/GITHUB_REPO_GUIDE_EN.md`
- `docs/GITHUB_REPO_GUIDE_TH.md`
พร้อมเชื่อมลิงก์จาก README เพื่อให้ทีมใช้งานง่ายขึ้น
