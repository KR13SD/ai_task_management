from dotenv import load_dotenv
load_dotenv()

import os
import sys
import time
import uuid
import json
import re
import logging
from typing import List, Optional, Literal
from datetime import datetime, date
from zoneinfo import ZoneInfo
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field
import uvicorn

# Google GenAI
from google import genai

# ---------------- Logging setup ----------------
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("task_planner")

# ---------------- Models ----------------
# ---------------- Models ----------------
Priority = Literal["Low", "Medium", "High"]

class SubTask(BaseModel):
    name: str = Field(description="ชื่องานย่อย", example="รวบรวมข้อมูลยอดขาย")
    description: str = Field(description="รายละเอียด/ขั้นตอนเพิ่มเติมของงานย่อย", example="ดึงรายงานยอดขายจากระบบ ERP และ Excel ของสาขา")

class PlanOut(BaseModel):
    task_name: str = Field(description="หัวข้อหลักของแผนงาน", example="เตรียมพรีเซนต์ยอดขายประจำสัปดาห์")
    start_date: str = Field(description="วันที่เริ่มต้นแผนงานในรูปแบบ YYYY-MM-DD", example="2024-08-21")
    end_date: str = Field(description="วันที่สิ้นสุดแผนงานในรูปแบบ YYYY-MM-DD", example="2024-08-23")
    priority: Priority = Field(description="ระดับความสำคัญของงาน", example="High")
    subtasks: List[SubTask] = Field(
        description="รายการของงานย่อยที่ต้องทำ (3-10 รายการ) โดยแต่ละงานมีชื่อและรายละเอียด",
        example=[
            {"name": "รวบรวมข้อมูลยอดขาย", "description": "ดึงรายงานยอดขายจาก ERP และไฟล์ Excel"},
            {"name": "จัดทำสไลด์นำเสนอ", "description": "ออกแบบโครงสไลด์และใส่ข้อมูลยอดขาย"},
            {"name": "ซ้อมการนำเสนอ", "description": "ซ้อมพูดตามสไลด์และจับเวลา"}
        ]
    )

class PlanResponse(BaseModel):
    plan: PlanOut

class UserRequest(BaseModel):
    input: str = Field(
        description="คำสั่งหรือคำขอของผู้ใช้ในรูปแบบภาษาธรรมชาติที่ต้องการให้ API วางแผนให้",
        example="ช่วยสร้าง to-do list สำหรับการเตรียมพรีเซนต์ยอดขายประจำสัปดาห์ให้หน่อย จะพรีเซนต์วันศุกร์นี้ ขอเริ่มเตรียมตัวตั้งแต่วันพุธ"
    )
    target_language: Optional[str] = Field(
        default=None,
        example="",
        description="ภาษาเป้าหมายสำหรับแผนงาน เช่น 'English', 'Thai' หากไม่ระบุจะใช้ภาษาเดียวกับที่ผู้ใช้ร้องขอ"
    )

# ---- Intent classifier schema ----
class IntentOut(BaseModel):
    intent: Literal["TASK_PLANNING", "NOT_TASK_PLANNING", "INCOMPLETE", "UNSAFE"]
    confidence: float = Field(ge=0.0, le=1.0)
    reason: str

# ---------------- Helpers ----------------
TH_TZ = ZoneInfo("Asia/Bangkok")

# --- Heuristic gibberish/invalid input detector ---
MIN_LEN = 8
_GIBBERISH_RE = re.compile(r'^[^A-Za-zก-๙0-9]+$')
_REPEAT_KEY_SMASH_RE = re.compile(r'(.)\1{4,}')
_LOW_ALPHA_RATIO_THRESHOLD = 0.2

def is_probably_gibberish(text: str) -> bool:
    t = (text or "").strip()
    if len(t) < MIN_LEN:
        return True
    if _GIBBERISH_RE.match(t):
        return True
    if _REPEAT_KEY_SMASH_RE.search(t):
        return True
    letters = re.findall(r'[A-Za-zก-๙]', t)
    ratio = len(letters) / max(len(t), 1)
    if ratio < _LOW_ALPHA_RATIO_THRESHOLD:
        return True
    return False

def make_prompt(user_text: str, today_iso: str, lang: Optional[str]) -> str:
    if lang:
        # ถ้ามีการระบุภาษา เปลี่ยนข้อความกำกับให้ชัดเจน
        lang_instruction = (
            f"The entire JSON output, including all string values (like `task_name` and `subtasks`), "
            f"must be written in {lang}. Use that language consistently."
        )
    else:
        # กรณีไม่ระบุภาษา ให้ model ตอบ “ตามภาษาของผู้ใช้” โดยตรวจจับอัตโนมัติ
        lang_instruction = (
            "Detect the user's request language automatically and respond in that same language. "
            "The entire JSON output, including all string values (like `task_name` and `subtasks`), "
            "must be in the user's request language. If the request mixes languages, use the predominant language."
        )

    prompt_text = f"""
You are a helpful task planner assistant. Your output must be ONLY a single JSON object matching the requested schema, with no other text or explanations.

{lang_instruction}

Hard constraints:
- This tool ONLY creates structured task plans. If the user's request is not about creating a plan/to-do/tasks, or lacks enough info to make a reasonable plan, DO NOT fabricate. Instead, STOP and produce a minimal plan using placeholders and mark missing fields explicitly as "TBD".
- Do not invent dates. If dates are ambiguous, infer conservatively relative to the current date.
- The current date is {today_iso} in the Asia/Bangkok timezone.

Requirements for the plan:
- Interpret natural language time references from the user's request.
- The `start_date` and `end_date` must be in YYYY-MM-DD (ISO) format, and `start_date` must be on or before `end_date`.
- The `priority` must be one of: "Low", "Medium", or "High", based on the urgency and deadline.
- Create between 3 and 10 concise, clear, and actionable subtasks.
Requirements for the plan:
- The `subtasks` field must be an array of JSON objects.
- Each object must have:
  - `name`: short subtask title
  - `description`: concise detail of what needs to be done

User's request:
\"\"\"{user_text}\"\"\"
"""
    return prompt_text.strip()

def classify_request(client: genai.Client, model_name: str, text: str) -> IntentOut:
    user_text = (text or "").strip()

    prompt = f"""
You are an intent classifier for the Task Planner API.

Classify the user's request into one of:
- TASK_PLANNING: The user is asking to create a plan/to-do/task schedule with a goal or outcome.
- NOT_TASK_PLANNING: The request is unrelated to creating a plan or tasks.
- INCOMPLETE: The request is too vague/insufficient to create a plan (e.g., missing goal, time window, or important context).
- UNSAFE: The request is inappropriate, e.g., inciting conflict/violence, hate, self-harm/harm to others, illegal activity, or otherwise unsafe.

Rules:
- If NOT_TASK_PLANNING or INCOMPLETE: Do not fabricate details. Downstream should generate a minimal plan with placeholders and mark missing fields as "TBD".
- If UNSAFE: Do not generate any plan/tasks.
- If TASK_PLANNING: Proceed as normal.

Return ONLY a single JSON object with fields: intent, confidence (0..1), reason (short and concise).

User's request:
\"\"\"{user_text}\"\"\"
"""

    cfg = {
        "response_mime_type": "application/json",
        "response_schema": IntentOut,
    }
    resp = client.models.generate_content(model=model_name, contents=prompt, config=cfg)
    if getattr(resp, "parsed", None):
        return resp.parsed
    data = json.loads(resp.text)
    return IntentOut(**data)

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("FastAPI startup")
    # TODO: เตรียม resource ที่ต้องใช้ตอนเริ่มระบบ (เช่น เชื่อมต่อฐานข้อมูล/แคช) ได้ที่นี่
    yield
    # TODO: ปิด/คืน resource ตอนหยุดระบบ
    logger.info("FastAPI shutdown")

API_DESCRIPTION = """
**ผู้ช่วยวางแผนงานอัจฉริยะ (Task Planner Assistant)**

API นี้ทำหน้าที่รับคำขอจากผู้ใช้ในรูปแบบภาษาธรรมชาติ (เช่น "วางแผนเที่ยวเชียงใหม่ 3 วัน") และแปลงเป็นแผนงาน (To-do list) ที่มีโครงสร้างชัดเจนในรูปแบบ JSON โดยใช้ความสามารถของ Google Gemini API

**ความสามารถหลัก:**
- แปลงภาษาพูดเป็นแผนงานที่มีโครงสร้าง
- ตีความวันและเวลาจากข้อความ (เช่น "วันศุกร์นี้", "สุดสัปดาห์หน้า")
- กำหนดระดับความสำคัญของงานอัตโนมัติ
- รองรับการตอบกลับหลายภาษา
"""

# ---------------- App ----------------
app = FastAPI(
    title="Task Planner API (FastAPI + Gemini)",
    version="1.0.0",
    lifespan=lifespan,
    description=API_DESCRIPTION,
)

# -------- Access log middleware (with timing & request id) --------
@app.middleware("http")
async def log_requests(request: Request, call_next):
    req_id = str(uuid.uuid4())[:8]
    request.state.req_id = req_id
    start = time.perf_counter()

    client_ip = getattr(request.client, "host", "-")
    logger.info(f"[{req_id}] ▶ {request.method} {request.url.path} from {client_ip}")

    try:
        response = await call_next(request)
        elapsed_ms = (time.perf_counter() - start) * 1000
        response.headers["X-Request-ID"] = req_id
        response.headers["X-Process-Time-ms"] = f"{elapsed_ms:.1f}"
        logger.info(f"[{req_id}] ◀ {request.method} {request.url.path} -> {response.status_code} in {elapsed_ms:.1f} ms")
        return response
    except Exception:
        elapsed_ms = (time.perf_counter() - start) * 1000
        logger.exception(f"[{req_id}] ✖ Unhandled error after {elapsed_ms:.1f} ms")
        raise

@app.get("/")
def Hello():
    logger.debug("Home called")
    return {"status": "Hello"}

@app.get("/health")
def health():
    logger.debug("Health check called")
    return {"status": "ok"}

@app.post("/plan", response_model=PlanResponse)
def plan(req: UserRequest, request: Request):
    req_id = getattr(request.state, "req_id", "-")
    logger.info(f"[{req_id}] Received /plan with input length={len(req.input)}")

    # วันปัจจุบัน (Asia/Bangkok)
    today_dt = datetime.now(TH_TZ).date()
    today_iso = today_dt.isoformat()
    logger.debug(f"[{req_id}] today_iso={today_iso}")

    # ตรวจคีย์ (ไม่แสดงค่าใน log)
    if not os.getenv("GEMINI_API_KEY"):
        logger.error(f"[{req_id}] Missing GEMINI_API_KEY/GOOGLE_API_KEY")
        raise HTTPException(status_code=500, detail="Missing GEMINI_API_KEY environment variable")
    
    # ตรวจสอบชื่อโมเดล
    model_name = os.getenv("GEMINI_MODEL")
    if not model_name:
        logger.error(f"[{req_id}] Missing GEMINI_MODEL environment variable")
        raise HTTPException(status_code=500, detail="Missing GEMINI_MODEL environment variable")

    # เตรียม client
    client = genai.Client()

    # ---------- 1) Pre-validation ----------
    user_text = req.input or ""
    if is_probably_gibberish(user_text):
        logger.info(f"[{req_id}] Reject: probable gibberish/too short")
        raise HTTPException(
            status_code=422,
            detail={
                "error": "invalid_input",
                "message": "คำขอไม่ชัดเจน กรุณาอธิบายสิ่งที่อยากให้วางแผน พร้อมช่วงเวลา/เดดไลน์คร่าว ๆ",
                "examples": [
                    "ช่วยวางแผนเตรียมพรีเซนต์ยอดขายประจำสัปดาห์ จะพรีเซนต์วันศุกร์นี้",
                    "วางแผนอ่านหนังสือสอบวิชาคณิต ภายใน 10 วัน",
                    "ช่วยจัดตารางออกกำลังกาย 4 สัปดาห์ เน้นลดไขมัน"
                ]
            }
        )

    # ---------- 2) Intent Gate ----------
    try:
        intent_out = classify_request(client, model_name, user_text)
        logger.info(f"[{req_id}] intent={intent_out.intent} conf={intent_out.confidence:.2f} reason={intent_out.reason}")
    except Exception:
        logger.exception(f"[{req_id}] Intent classification failed")
        raise HTTPException(status_code=502, detail="Intent classification failed")

    if intent_out.intent == "UNSAFE":
        logger.warning(f"[{req_id}] Reject: unsafe content detected. Reason: {intent_out.reason}")
        raise HTTPException(
            status_code=400,
            detail={
                "error": "unsafe_content",
                "message": "คำขอของคุณมีเนื้อหาที่ไม่เหมาะสมและไม่สามารถดำเนินการได้",
                "classifier_reason": intent_out.reason,
            }
        )

    if intent_out.intent in ("NOT_TASK_PLANNING",) or (intent_out.intent == "INCOMPLETE" and intent_out.confidence < 0.8):
        raise HTTPException(
            status_code=422,
            detail={
                "error": "not_task_planning_or_incomplete",
                "message": "คำขอยังไม่ชัดเจนพอสำหรับการวางแผน กรุณาระบุเป้าหมายและกรอบเวลา",
                "classifier_reason": intent_out.reason,
                "hints": [
                    "เป้าหมาย/หัวข้อที่ต้องการวางแผนคืออะไร",
                    "กรอบเวลาเริ่ม–สิ้นสุด หรือเดดไลน์",
                    "เงื่อนไข/ข้อจำกัดสำคัญ (เช่น งบประมาณ, ทรัพยากร, ช่องทาง)"
                ]
            }
        )

    # ---------- 3) สร้าง Prompt + Config ----------
    config = {
        "response_mime_type": "application/json",
        "response_schema": PlanOut,
    }
    prompt = make_prompt(user_text, today_iso, lang=req.target_language)
    if logger.isEnabledFor(logging.DEBUG):
        preview = prompt[:300].replace("\n", " ")
        logger.debug(f"[{req_id}] Prompt preview: {preview}... (len={len(prompt)})")

    # ---------- 4) เรียก Planner Model ----------
    try:
        logger.info(f"[{req_id}] Calling Gemini model={model_name}")
        t0 = time.perf_counter()
        resp = client.models.generate_content(
            model=model_name,
            contents=prompt,
            config=config,
        )
        call_ms = (time.perf_counter() - t0) * 1000
        logger.info(f"[{req_id}] Gemini responded in {call_ms:.1f} ms")
    except Exception as e:
        logger.exception(f"[{req_id}] Gemini API error")
        raise HTTPException(status_code=502, detail=f"Gemini API error: {e}")

    parsed: Optional[PlanOut] = getattr(resp, "parsed", None)
    if parsed:
        logger.info(f"[{req_id}] Parsed via schema OK: task_name='{parsed.task_name}', subtasks={len(parsed.subtasks)}")
    else:
        logger.warning(f"[{req_id}] No .parsed, trying to parse from .text fallback")
        try:
            data = json.loads(resp.text)
            parsed = PlanOut(**data)
            logger.info(f"[{req_id}] Fallback parse OK: task_name='{parsed.task_name}', subtasks={len(parsed.subtasks)}")
        except Exception:
            logger.exception(f"[{req_id}] Failed to parse model response into PlanOut schema")
            raise HTTPException(status_code=500, detail="Failed to parse model response into PlanOut schema")

    logger.debug(f"[{req_id}] start_date=({parsed.start_date}), end_date=({parsed.end_date})")

    return PlanResponse(plan=parsed)

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000, log_level=LOG_LEVEL.lower(), access_log=True)

# --- วิธีการรัน ---
#
# 1. ติดตั้ง dependency ให้ครบ (fastapi, uvicorn, pydantic, google-genai ฯลฯ)
# 2. ในไฟล์ .env ให้เพิ่มคีย์และชื่อโมเดล:
#       GEMINI_API_KEY="YOUR_API_KEY_HERE"
#       GEMINI_MODEL="gemini-1.5-pro"
#       GEMINI_CLASSIFIER_MODEL="gemini-1.5-flash"  # หรือจะใช้ตัวเดียวกับ GEMINI_MODEL ก็ได้
# 3. รันแอปพลิเคชันด้วยคำสั่ง:
#       python api.py
# 4. API จะพร้อมใช้งานที่ http://127.0.0.1:8000
#    Swagger UI: http://127.0.0.1:8000/docs
#    Document : http://127.0.0.1:8000/redoc