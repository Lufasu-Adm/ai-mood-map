import os
import json
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from groq import Groq
from dotenv import load_dotenv

# 1. Setup Environment & API Client
load_dotenv() # Load .env file

# Pastikan file .env berisi: GROQ_API_KEY=gsk_xxxx
client = Groq(api_key=os.getenv("GROQ_API_KEY"))

app = FastAPI(title="Mood Map AI - Llama 3 Powered")

class JournalInput(BaseModel):
    text: str
    mood_score: int

# --- SYSTEM PROMPT (UPDATED FOR SAFETY) ---
SYSTEM_PROMPT = """
Kamu adalah AI asisten kesehatan mental yang empatik dan profesional.
Tugasmu adalah menganalisis jurnal harian pengguna.

Output HARUS berupa JSON murni dengan struktur berikut:
{
    "sentiment": "Positif/Netral/Negatif/BAHAYA",
    "emotional_tags": ["tag1", "tag2"],
    "summary": "Ringkasan 1 kalimat tentang perasaan user dalam Bahasa Indonesia yang hangat.",
    "tips": ["Saran aksi konkret 1", "Saran aksi konkret 2"],
    "is_crisis": boolean
}

ATURAN PENTING:
1. Jika teks mengandung keinginan bunuh diri, self-harm, atau keputusasaan akut:
   - Set "is_crisis": true
   - Set "sentiment": "BAHAYA"
   - Isi "tips" dengan: ["JANGAN SENDIRIAN", "HUBUNGI BANTUAN PROFESIONAL SEGERA"]
2. Gunakan Bahasa Indonesia yang gaul tapi sopan (akrab).
3. Jangan berikan output teks lain selain JSON.
"""

@app.get("/")
def read_root():
    return {"status": "AI Brain is Online 🧠"}

@app.post("/analyze")
async def analyze_journal(entry: JournalInput):
    try:
        # 2. Kirim Request ke Llama 3 via Groq
        chat_completion = client.chat.completions.create(
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": f"Jurnal: {entry.text}\nMood Score User: {entry.mood_score}/100"}
            ],
            model="llama-3.3-70b-versatile", # Model cepat & cerdas
            temperature=0.6,                 # Agak rendah biar konsisten JSON-nya
            response_format={"type": "json_object"} # Memaksa output JSON
        )

        # 3. Parsing Hasil
        ai_response = chat_completion.choices[0].message.content
        result_json = json.loads(ai_response)

        # --- LOGIKA KRISIS ---
        # Ambil list tips dari AI
        tips_list = result_json.get("tips", [])
        
        # Jika AI bilang ini krisis, kita paksa masukkan tag "CRISIS"
        # Tag ini yang akan dibaca oleh Flutter untuk memunculkan Layar Merah
        if result_json.get("is_crisis", False) == True:
            tips_list.insert(0, "CRISIS")

        # 4. Return sesuai format yang diharapkan Flutter
        return {
            "received_text": entry.text,
            "ai_analysis": {
                "sentiment": result_json.get("sentiment", "Netral"),
                "summary": result_json.get("summary", "Gagal merangkum."),
                "tips": tips_list # List yang mungkin berisi tag "CRISIS"
            }
        }

    except Exception as e:
        print(f"Error: {e}")
        # Fallback mechanism biar aplikasi gak crash
        return {
            "received_text": entry.text,
            "ai_analysis": {
                "sentiment": "Error",
                "summary": "Maaf, AI sedang pusing (Server Error).",
                "tips": ["Coba lagi nanti."]
            }
        }