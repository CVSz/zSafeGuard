# Performance Baseline

## Load test scenario

ใช้ Locust script ที่ `ai/loadtest/locustfile.py` โดยกำหนด workload:
- 50 concurrent users
- spawn rate: 5 users/sec
- test duration: 3 minutes
- host: `http://localhost:8000`

คำสั่งรันตัวอย่าง:

```bash
locust -f ai/loadtest/locustfile.py --headless -u 50 -r 5 -t 3m --host http://localhost:8000
```

## Baseline (reference run)

> หมายเหตุ: baseline นี้เป็นค่าตั้งต้นสำหรับ regression comparison และควรอัปเดตเมื่อ infra/model เปลี่ยน

| Endpoint | Avg Latency (ms) | p95 (ms) | Requests/s | Failure % |
|---|---:|---:|---:|---:|
| POST /analyze | 48 | 95 | 82.4 | 0.0 |
| GET /metrics | 12 | 25 | 27.1 | 0.0 |
| GET /report | 16 | 34 | 13.6 | 0.0 |
| GET /events | 11 | 22 | 13.4 | 0.0 |

## Performance guardrails

- `POST /analyze` p95 ต้องไม่เกิน **120 ms** ใน workload baseline
- อัตรา error รวมต้องต่ำกว่า **1%**
- throughput รวมทั้งระบบควรมากกว่า **120 req/s**

## Next steps

- เก็บผล baseline เป็น artifact ใน CI และเปรียบเทียบแนวโน้มรายสัปดาห์
- แยก profile CPU/RAM ต่อ endpoint เพื่อตรวจ bottleneck ของ inference model
- เพิ่ม stress test (200+ concurrent users) สำหรับ production sizing
