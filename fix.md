# Production Readiness & Bug Fix Roadmap

This document outlines the phased transition of ProjectAlpha from its current state to a production-ready microservices architecture.

## Overview of Current Architecture
The project currently consists of:
- **`api/`**: Python FastAPI backend.
- **`truck/`**: Flutter (Dart) mobile/desktop application.
- **`web-app/`**: Vanilla JavaScript/HTML web interface.
- **Infrastructure**: Dockerized environment managed via `docker-compose`.

---

## Phase 1: Immediate Stability & Critical Bug Fixes
*Focus: Stabilizing core workflows and data integrity.*

### 1. Fix User Role Misconfiguration
- **Bug:** New registrations default to `CUSTOMER` due to hardcoded frontend/backend defaults.
- **Fix:**
    - **Frontend:** Remove `'customer'` defaults in `web-app/js/app.js` and `web-app/js/helpers.js`. Update UI to mandate role selection before API submission.
    - **Backend:** Remove `default=UserRole.CUSTOMER` from `api/app/models/models.py`. Update registration logic in `api/app/api/v1/auth.py` to require an explicit role from the payload.

### 2. Implement Atomic Truck Linking Logic
- **Bug:** Missing logic to assign "free" trucks to customer requests.
- **Fix:**
    - **Backend:** Update `api/app/api/v1/jobs.py` within `create_job` to implement a transactional lookup.
    - **Logic:** Query trucks matching requested class where no active/unexpired `TruckLock` exists. Atomically create `Job` and `TruckLock` records to prevent race conditions.

---

## Phase 2: Security & Data Hardening
*Focus: Protecting data and ensuring secure authentication.*

- **Authentication/Authorization:** Transition to robust JWT-based authentication with secure token storage (server-side).
- **Environment Management:** Formalize `.env` management (currently `.env.example` exists; ensure CI/CD injects actual secrets securely).
- **Input Validation:** Implement strict Pydantic schemas in `api/app/schemas/` to sanitize all API inputs.

---

## Phase 3: Infrastructure Scalability
*Focus: Readying the system for traffic and reliability.*

- **Database Management:** Move from local/embedded-like behavior to a managed PostgreSQL cluster with Alembic for automated migrations.
- **Load Balancing:** Refine `nginx.conf` to properly route traffic between the API, Web App, and internal services, adding SSL termination.
- **Observability:** Integrate structured logging (e.g., `structlog`) in the Python backend to enable centralized log analysis (e.g., ELK or Grafana Loki).

---

## Phase 4: Operational Excellence (CI/CD)
*Focus: Automating quality assurance and deployment.*

- **Automated Testing:** Implement Pytest for backend integration tests (testing job creation flows) and unit tests for role logic.
- **CI/CD Pipeline:** Automate Docker image building, scanning, and deployment (GitHub Actions/GitLab CI) to ensure consistent environment parity.
- **Documentation:** Maintain `GEMINI.md` and `situation.md` as live, versioned documentation of the system's architectural constraints.
