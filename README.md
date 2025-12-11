# 🧠 Mood Map AI - Intelligent Mental Health Tracker

![Flutter](https://img.shields.io/badge/Flutter-3.10-02569B?logo=flutter)
![Python](https://img.shields.io/badge/Python-3.10-3776AB?logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.95-009688?logo=fastapi)
![AI Model](https://img.shields.io/badge/AI-Llama%203.3-orange)

**Mood Map AI** adalah aplikasi jurnal kesehatan mental berbasis *Privacy-First* yang menggunakan kecerdasan buatan (Llama 3.3 via Groq) untuk menganalisis emosi, memberikan *coping tips* yang personal, dan memvisualisasikan tren suasana hati pengguna.

Aplikasi ini dirancang dengan arsitektur **Hybrid**: Data disimpan aman secara lokal (Offline-First) di perangkat pengguna, sementara pemrosesan AI dilakukan secara *stateless* melalui backend yang aman.

---

## 📸 Screenshots

| Dashboard & Chart | AI Analysis | Safety/Crisis Alert |
|:-----------------:|:-----------:|:-------------------:|
| <img src="URL_GAMBAR_CHART_KAMU" width="250" /> | <img src="URL_GAMBAR_AI_RESPONSE" width="250" /> | <img src="URL_GAMBAR_CRISIS_ALERT" width="250" /> |

> *Ganti `URL_GAMBAR` di atas dengan link gambar/screenshot aplikasi kamu.*

---

## ✨ Fitur Utama

### 📱 Mobile (Flutter)
- **Daily Check-in:** Input jurnal teks dan *mood slider* (0-100) yang interaktif.
- **Mood Visualization:** Grafik interaktif (menggunakan `fl_chart`) untuk melihat tren emosi mingguan.
- **Local Database:** Penyimpanan data menggunakan **Drift (SQLite)**, memastikan data tetap ada meski tanpa internet.
- **Crisis Detection System:** Deteksi otomatis kata kunci bahaya (self-harm/suicide) dengan tampilan *Emergency Alert* dan arahan ke bantuan profesional.

### 🧠 Backend (FastAPI + AI)
- **Llama 3.3 Powered:** Menggunakan model LLM terbaru via Groq API untuk analisis sentimen yang dalam & empatik.
- **Contextual Advice:** Memberikan saran (*coping mechanism*) yang sesuai dengan konteks cerita pengguna.
- **Safety Guardrails:** Sistem prompt khusus untuk memfilter dan menangani konten sensitif/berbahaya.

---

## 🛠️ Tech Stack

### Mobile App
- **Framework:** Flutter (Dart)
- **State Management:** `setState` (Simple & Effective for MVP)
- **Networking:** Dio
- **Database:** Drift (SQLite Abstraction)
- **UI Components:** FL Chart, Google Fonts

### Backend API
- **Framework:** FastAPI (Python)
- **AI Engine:** Groq SDK (Llama-3.3-70b-versatile)
- **Security:** `python-dotenv` for API Key management

---

## 🚀 Cara Menjalankan (Installation)

### Prasyarat
- Flutter SDK Terinstall
- Python 3.8+
- API Key dari [Groq Console](https://console.groq.com/) (Gratis)

### 1. Setup Backend
```bash
cd backend
python -m venv venv
# Windows
.\\venv\\Scripts\\activate
# Mac/Linux
source venv/bin/activate

pip install -r requirements.txt
# Atau install manual: pip install fastapi uvicorn groq python-dotenv
```

Konfigurasi Environment: Buat file `.env` di dalam folder `backend/`:
```
GROQ_API_KEY=gsk_your_api_key_here
```

Jalankan Server:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Setup Mobile (Flutter)
Pastikan server backend sudah berjalan.

Konfigurasi IP Address: Buka `mobile/lib/main.dart` dan ubah `_backendUrl` sesuai IP Laptop kamu (karena Emulator/HP Fisik tidak bisa baca localhost).
// Contoh (Ganti dengan IP Laptop kamu, cek via ipconfig/ifconfig)
final String _backendUrl = "http://192.168.1.x:8000/analyze";

Jalankan Aplikasi:
```bash
cd mobile
flutter pub get
flutter run
# Atau build APK: flutter build apk --release
```

📂 Struktur Proyek (Monorepo)
```
ai-mood-map/
├── backend/            # Python Server Logic
│   ├── main.py         # API Endpoints & AI Logic
│   └── .env            # API Keys (GitIgnored)
│
└── mobile/             # Flutter App
    ├── lib/
    │   ├── database/   # Local Storage (Drift)
    │   ├── widgets/    # UI Components (Charts)
    │   └── main.dart   # Main App Logic
    └── pubspec.yaml    # Dependencies
```

⚠️ Disclaimer & Safety
Aplikasi ini dikembangkan sebagai proyek portofolio/edukasi. Analisis AI yang dihasilkan bukanlah pengganti diagnosis atau bantuan medis profesional.

Fitur Crisis Detection bekerja berdasarkan pengenalan pola teks dan tidak menjamin akurasi 100%.

Jika Anda atau seseorang yang Anda kenal sedang dalam krisis, harap segera hubungi profesional atau layanan darurat setempat.
