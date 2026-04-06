# zSafeGuard Architecture (C4 Model)

เอกสารนี้สรุปสถาปัตยกรรมระบบ zSafeGuard ตามแนวคิด C4 (Context, Container, Component)
เพื่อช่วยให้ทีม Dev/Ops/Data เข้าใจขอบเขตระบบและจุดเชื่อมต่ออย่างเป็นระบบ

## 1) System Context

```mermaid
flowchart LR
  Analyst[Risk Analyst / Operator]
  ExtData[External Data Source]
  zSG[zSafeGuard Platform]
  Notifier[Alert/Notification Channel]

  Analyst -->|Monitor + trigger simulation| zSG
  ExtData -->|Feature data| zSG
  zSG -->|Risk report + events| Analyst
  zSG -->|Risk alerts| Notifier
```

**คำอธิบาย:**
- ผู้ใช้หลักคือ Analyst/Operator ที่ดูสถานะความเสี่ยงผ่าน Dashboard
- ข้อมูลภายนอกถูกแปลงเป็น feature vector แล้วส่งเข้า AI API
- ระบบส่งผลวิเคราะห์ความเสี่ยงและเหตุการณ์แบบ real-time กลับให้ผู้ใช้

## 2) Container Diagram

```mermaid
flowchart LR
  subgraph Client Tier
    Dashboard[Next.js Dashboard]
  end

  subgraph Application Tier
    API[FastAPI AI Service]
    Stream[SSE Stream Endpoint]
    Analytics[Metrics/Report Endpoints]
  end

  subgraph Data/Model Tier
    ModelXGB[(xgb.pkl)]
    ModelNN[(nn.pkl)]
    EventStore[(In-memory event deque)]
  end

  Dashboard -->|POST /analyze| API
  Dashboard -->|GET /stream| Stream
  Dashboard -->|GET /metrics,/report,/events| Analytics

  API --> ModelXGB
  API --> ModelNN
  API --> EventStore
  Stream --> EventStore
  Analytics --> EventStore
```

**คำอธิบาย:**
- Dashboard เป็น UI สำหรับจำลองข้อมูลและดูผล
- AI Service รับ request, เรียก ensemble model, และจัดเก็บเหตุการณ์ล่าสุดในหน่วยความจำ
- Stream/Analytics endpoint ใช้ event store ร่วมกันเพื่อรองรับหน้าจอ real-time

## 3) Component Diagram (AI Service)

```mermaid
flowchart TD
  Router[FastAPI Router]
  Schema[Pydantic Schemas]
  Validator[Request/Query Validation]
  Inference[Inference Service]
  Ensemble[Ensemble Module]
  Store[Event Queue]
  Reporter[Metrics/Report Builder]

  Router --> Schema
  Schema --> Validator
  Router --> Inference
  Inference --> Ensemble
  Inference --> Store
  Router --> Reporter
  Reporter --> Store
```

**คำอธิบาย:**
- Router จัดการ endpoint และ OpenAPI schema
- Pydantic schema รับผิดชอบ contract ของ request/response
- Inference service ใช้โมเดล ensemble (`xgb` และ `nn`) เพื่อสร้าง score
- Reporter คำนวณ aggregation จาก event queue เพื่อรายงานผลเชิงสถิติ

## 4) Deployment View (ย่อ)

- Runtime หลัก: Docker container ของ FastAPI service
- รองรับ Kubernetes deployment ผ่านไฟล์ใน `k8s/`
- CI/CD pipeline ทำการรัน test และ build image อัตโนมัติบน branch หลัก
