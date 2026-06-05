<p align="center">
  <h1 align="center">🌸 IrisIQ — Flower Classification Engine</h1>
  <p align="center">
    <strong>A portfolio-grade, production-ready AI-powered Iris Flower Classification Application</strong>
  </p>
  <p align="center">
    Flutter • Rust • Scikit-Learn • ONNX • SQLite • Docker
  </p>
</p>

---

## 📋 Overview

IrisIQ is a full-stack AI application that predicts Iris flower species (**Setosa**, **Versicolor**, **Virginica**) from sepal and petal measurements. It features:

- A **Python ML pipeline** that trains a Random Forest Classifier and exports it to ONNX format
- A **Rust backend** (Actix-Web) that loads the ONNX model for native inference with sub-millisecond latency
- A **Flutter frontend** with Material 3, Riverpod state management, glassmorphism UI, and responsive layouts
- **SQLite** database for prediction history logging
- **Docker** containerization for one-command deployment

## 🏗 Architecture

```
┌────────────────────┐     REST API      ┌──────────────────────┐
│   Flutter Frontend │ ◄──────────────►  │    Rust Backend      │
│   (Web/Mobile/     │     HTTP/JSON     │    (Actix-Web)       │
│    Desktop)        │                   │                      │
│                    │                   │  ┌────────────────┐  │
│  • Material 3      │                   │  │  tract-onnx    │  │
│  • Riverpod        │                   │  │  (ONNX Engine) │  │
│  • GoRouter        │                   │  └────────────────┘  │
│  • fl_chart        │                   │  ┌────────────────┐  │
│  • Glassmorphism   │                   │  │  SQLite (sqlx) │  │
└────────────────────┘                   │  └────────────────┘  │
                                         └──────────────────────┘
```

## 📂 Project Structure

```
Flower_Classification/
├── ml/                          # Machine Learning Pipeline
│   ├── train.py                 # Training, evaluation, ONNX export
│   ├── requirements.txt         # Python dependencies
│   ├── model.onnx               # Exported model artifact
│   └── model_metadata.json      # Metrics & dataset info
│
├── backend/                     # Rust Backend API
│   ├── Cargo.toml               # Rust dependencies
│   ├── migrations/              # SQLite schema migrations
│   ├── resources/               # ONNX model + metadata
│   └── src/
│       ├── main.rs              # Server entrypoint
│       ├── model.rs             # Data structures
│       ├── inference.rs         # ONNX model execution
│       ├── db.rs                # Database queries
│       └── handlers.rs          # API route handlers
│
├── frontend/                    # Flutter Application
│   ├── lib/
│   │   ├── main.dart            # App entrypoint
│   │   ├── core/
│   │   │   ├── theme/           # Material 3 themes
│   │   │   ├── routing/         # GoRouter configuration
│   │   │   ├── network/         # Dio API client
│   │   │   └── utils/           # CSV exporter
│   │   ├── data/models/         # JSON model classes
│   │   └── presentation/
│   │       ├── providers/       # Riverpod state management
│   │       ├── screens/         # 7 application screens
│   │       └── widgets/         # Shared components
│   └── pubspec.yaml
│
├── Iris.csv                     # Dataset (Kaggle format)
├── Dockerfile                   # Multi-stage Docker build
├── docker-compose.yml           # Deployment orchestration
└── README.md                    # This file
```

## 🚀 Quick Start

### Prerequisites

- **Python 3.10+** (for ML pipeline)
- **Rust 1.75+** (for backend)
- **Flutter 3.x** (for frontend)
- **Docker** (optional, for containerized deployment)

### 1. Train the ML Model

```bash
cd ml
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python3 train.py
```

This produces `model.onnx` and `model_metadata.json`. Copy them to backend:

```bash
cp model.onnx ../backend/resources/
cp model_metadata.json ../backend/resources/
```

### 2. Run the Rust Backend

```bash
cd backend
cargo run --release
```

The API server starts on `http://localhost:8080`.

### 3. Run the Flutter Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome    # For web
flutter run              # For mobile/desktop
```

### 4. Docker Deployment (Optional)

```bash
# Build Flutter web assets first
cd frontend && flutter build web --release && cd ..

# Then build and run with Docker Compose
docker compose up --build
```

Access the app at `http://localhost:8080`.

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/predict` | Run ONNX inference on input features |
| `GET` | `/api/history` | Fetch prediction history (paginated) |
| `DELETE` | `/api/history/{id}` | Delete a specific prediction |
| `DELETE` | `/api/history` | Clear all prediction history |
| `GET` | `/api/metrics` | Get model metrics and usage stats |
| `GET` | `/api/health` | API health check |

### Example Prediction Request

```bash
curl -X POST http://localhost:8080/api/predict \
  -H "Content-Type: application/json" \
  -d '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}'
```

## 📊 Model Performance

| Metric | Score |
|--------|-------|
| Train Accuracy | 100.0% |
| Test Accuracy | 93.3% |
| Precision | 93.3% |
| Recall | 93.3% |
| F1 Score | 93.3% |

## 🎨 Application Screens

1. **Landing Screen** — Premium hero section with animated flower graphics
2. **Prediction Screen** — Slider/text inputs with validation
3. **Result Screen** — Confidence gauge, species profile, probability bars
4. **History Screen** — Searchable, paginated prediction logs
5. **Analytics Dashboard** — Pie/bar charts, dataset insights
6. **Model Info Screen** — Confusion matrix, per-class metrics
7. **Settings Screen** — Theme toggle, API health monitor

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x, Dart, Material 3, Riverpod, GoRouter, fl_chart |
| Backend | Rust, Actix-Web, Tokio, sqlx, tract-onnx |
| ML | Python, Scikit-Learn, skl2onnx |
| Database | SQLite |
| Deployment | Docker, Docker Compose |

## 📄 License

This project is developed for portfolio and educational purposes.

---

<p align="center">
  Built with ❤️ using Flutter, Rust, and Python
</p>
