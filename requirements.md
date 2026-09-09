# Naql — Requirements

This document lists all dependencies and system requirements needed to build and run ProjectAlpha.

---

## System Prerequisites

| Tool          | Minimum Version | Notes                                      |
|---------------|-----------------|--------------------------------------------|
| Docker        | 24.0+           | For containerized deployment               |
| Docker Compose| 2.20+           | Included with Docker Desktop               |
| Node.js       | 20.x            | Required for Next.js frontend build        |
| npm           | 10.x            | Included with Node.js                      |
| Python        | 3.11            | Required for FastAPI backend               |
| Flutter       | 3.12+           | For mobile/desktop app development        |
| Dart          | 3.3+            | Included with Flutter                      |
| MySQL client  | 8.0+            | For database management (optional)         |

---

## Backend Dependencies (Python)

Source: `api/requirements.txt`

| Package                       | Version     | Purpose                                            |
|-------------------------------|-------------|----------------------------------------------------|
| `fastapi`                     | 0.110.0     | Web API framework                                  |
| `uvicorn[standard]`           | 0.27.1      | ASGI server                                        |
| `sqlalchemy[asyncio]`         | 2.0.27      | Async ORM                                          |
| `aiomysql`                    | 0.2.0       | Async MySQL driver for SQLAlchemy                  |
| `pydantic[email]`             | 2.6.3       | Data validation and settings                       |
| `python-jose[cryptography]`   | 3.3.0       | JWT token handling                                 |
| `passlib[argon2]`             | 1.7.4       | Password hashing (argon2id)                        |
| `python-multipart`            | 0.0.9       | Form data parsing                                  |
| `python-dotenv`               | 1.0.1       | Environment variable loading                       |
| `cryptography`                | 42.0.5      | Cryptographic primitives                           |
| `httpx`                       | 0.27.0      | Async HTTP client                                  |
| `pytest`                      | 8.0.2       | Testing framework                                  |
| `pytest-asyncio`              | 0.23.5      | Async test support                                 |
| `alembic`                     | latest      | Database migrations                                |
| `structlog`                   | latest      | Structured logging                                 |

### Install backend dependencies

```sh
cd api
pip install -r requirements.txt
```

---

## Frontend Dependencies (Node.js / Next.js)

Source: `frontend/package.json`

| Package                      | Version     | Purpose                                    |
|------------------------------|-------------|--------------------------------------------|
| `next`                       | 16.3.4      | React framework                            |
| `react`                      | 19.2.8      | UI library                                 |
| `react-dom`                  | 19.2.8      | DOM rendering                              |
| `react-leaflet`              | ^5.0.0      | Map component                              |
| `leaflet`                    | ^1.9.4      | Map engine                                 |
| `@types/leaflet`             | ^1.9.22     | TypeScript types for leaflet               |
| `@types/react-leaflet`       | ^2.8.3      | TypeScript types for react-leaflet         |
| `@tailwindcss/postcss`       | ^4          | Tailwind CSS build plugin                  |
| `tailwindcss`                | ^4          | Utility-first CSS framework                |
| `typescript`                 | ^5          | Type-safe JavaScript                       |
| `eslint`                     | ^9          | Linter                                     |
| `eslint-config-next`         | 16.3.4      | Next.js ESLint rules                       |
| `@types/node`                | ^20         | Node.js TypeScript types                   |
| `@types/react`               | ^19         | React TypeScript types                     |
| `@types/react-dom`           | ^19         | React DOM TypeScript types                 |

### Install frontend dependencies

```sh
cd frontend
npm install
```

---

## Mobile App Dependencies (Flutter / Dart)

Source: `lib/pubspec.yaml`

| Package                    | Version     | Purpose                                    |
|----------------------------|-------------|--------------------------------------------|
| `flutter`                  | sdk         | Mobile/UI framework                        |
| `flutter_map`              | ^6.2.1      | Map widget                                 |
| `latlong2`                 | ^0.9.0      | Coordinate types                           |
| `google_fonts`             | ^6.2.1      | Custom typography                          |
| `http`                     | ^1.2.1      | HTTP client                                |
| `flutter_secure_storage`   | ^9.0.0      | Encrypted local storage (tokens)           |
| `provider`                 | ^6.1.2      | State management                           |
| `shared_preferences`       | ^2.3.3      | Simple local key-value storage             |
| `flutter_test`             | sdk         | Testing framework                          |
| `flutter_lints`            | ^5.0.0      | Lint rules                                 |

### Install Flutter dependencies

```sh
cd lib
flutter pub get
```

---

## Infrastructure Dependencies

Defined by `docker-compose.yml`:

| Service     | Image         | Purpose                          |
|-------------|---------------|----------------------------------|
| `frontend`  | node:20       | Next.js production server        |
| `api`       | python:3.11   | FastAPI backend                  |
| `database`  | mysql:8.0     | Relational data store            |

### Named volumes

| Volume          | Mount path        | Purpose                |
|-----------------|-------------------|------------------------|
| `naql_mysql_data` | `/var/lib/mysql` | Persistent database   |
| `./exports`       | `/app/exports`  | Auto-generated CSV    |

---

## Environment Configuration

Copy the example file and fill in secure values:

```sh
cp .env.example .env
```

Required variables:

| Variable             | Example                              | Purpose                          |
|----------------------|--------------------------------------|----------------------------------|
| `MYSQL_DATABASE`     | `naql`                               | Database name                    |
| `MYSQL_USER`         | `naql_app`                           | Application database user        |
| `MYSQL_PASSWORD`     | `replace-with-a-unique-long-password`| Application user password        |
| `MYSQL_ROOT_PASSWORD`| `replace-with-a-different-unique-long-root-password` | Root password        |
| `SECRET_KEY`         | `replace-with-a-unique-random-64-character-secret` | JWT signing key |

---

## Quick Start

```sh
# 1. Set up environment
cp .env.example .env

# 2. Start all services
docker compose up --build

# 3. (Optional) Run tests
cd api && python -m pytest tests/ -v
cd lib && flutter test
```

### Access URLs

| Service     | URL                        |
|-------------|----------------------------|
| Web         | http://localhost:3000      |
| API         | http://localhost:8000      |
| API docs    | http://localhost:8000/docs |
| MySQL       | localhost:3306 (private)   |

---

## Development Setup (Without Docker)

### Backend

```sh
cd api
python -m venv venv
source venv/bin/activate  # Linux/macOS
# venv\Scripts\activate    # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Frontend

```sh
cd frontend
npm install
npm run dev
```

### Flutter

```sh
cd lib
flutter pub get
flutter run
```