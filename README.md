# NoteFlow — Kamka DevOps Assessment

A minimal 3-tier notes application built as a vehicle to demonstrate a complete DevOps deployment lifecycle: containerization, CI/CD pipeline, monitoring, and deployment automation.

**Live deployment:** https://noteflow-frontend-hmf6.onrender.com

---

## Architecture Overview

```
[ LOCAL DEVELOPMENT STACK (Docker Compose) ]
┌────────────────────────────────────────────────────────┐
│  ┌──────────────┐      ┌──────────────┐                │
│  │  Angular FE  │ ───> │ Spring Boot  │                │
│  │  (Port 80)   │      │ API (8080)   │                │
│  └──────────────┘      └──────┬───────┘                │
│                               │                        │
│  ┌──────────────┐             ▼                        │
│  │   MySQL DB   │      ┌──────────────┐                │
│  │ (Local Data) │      │  Prometheus  │ ──>  Grafana   │
│  └──────────────┘      │ (Port 9090)  │     (Port 3000)│
│                        └──────────────┘                │
└────────────────────────────────────────────────────────┘

[ CI/CD PIPELINE ]
git push ──> GitHub Actions ──> Build & Push ──> GHCR
                                                    │
                                          (Deploy Hook)
                                                    │
                                                    ▼
[ LIVE PRODUCTION ENVIRONMENT (Render Cloud) ]
┌────────────────────────────────────────────────────────┐
│  ┌──────────────────┐      ┌──────────────┐            │
│  │   Render Proxy   │ ───> │  Angular FE  │            │
│  │(SSL Termination) │      │ (Static/Prod)│            │
│  └─────────┬────────┘      └──────┬───────┘            │
│            │                      │                    │
│            ▼                      ▼                    │
│  ┌──────────────────┐      ┌──────────────┐            │
│  │   Render Proxy   │ ───> │ Spring Boot  │            │
│  │(SSL Termination) │      │  API (8080)  │            │
│  └──────────────────┘      └──────┬───────┘            │
│                                   ▼                    │
│                            ┌──────────────┐            │
│                            │  PostgreSQL  │            │
│                            │  (Managed)   │            │
│                            └──────────────┘            │
└────────────────────────────────────────────────────────┘
```

| Layer | Local | Production (Render) |
|-------|-------|---------------------|
| Frontend | Angular 18 + Nginx (Dockerfile.dev) | Angular 18 + Nginx (Dockerfile) |
| Backend | Spring Boot 3 + Java 17 | Spring Boot 3 + Java 17 |
| Database | MySQL 8 (Docker container) | PostgreSQL 15 (Render managed) |
| Monitoring | Prometheus + Grafana (docker-compose) | /actuator/health + /actuator/prometheus |
| Registry | Local Docker images | GHCR (ghcr.io) |

---

## Quick Start — Local (docker-compose)

### Prerequisites
- Docker Desktop installed and running
- Git

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/medaminenj/kamka-assessment.git
cd kamka-assessment
```

**2. Create your .env file**
```bash
cp .env.example .env
```

Edit `.env` with your values:
```
DATABASE_PASSWORD=root123
CORS_ALLOWED_ORIGINS=http://localhost
GRAFANA_PASSWORD=admin123
```

**3. Start the full stack**
```bash
docker-compose up -d
```

This single command starts all 5 services:
- MySQL database
- Spring Boot backend
- Angular/Nginx frontend
- Prometheus monitoring
- Grafana dashboards

**4. Verify everything is running**
```bash
docker-compose ps
```

### Access the services

| Service | URL | Credentials |
|---------|-----|-------------|
| App | http://localhost | — |
| Backend API | http://localhost:8080 | — |
| Health check (backend) | http://localhost:8080/actuator/health | — |
| Health check (frontend) | http://localhost/health | — |
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3000 | admin / admin123 |
| Metrics | http://localhost:8080/actuator/prometheus | — |

---

## Secrets Management

Secrets are never committed to the repository.

- `.env` — real values, listed in `.gitignore`, never committed
- `.env.example` — template with placeholder values, committed as documentation
- Production secrets — set directly in Render dashboard environment variables

To supply your own secrets as a reviewer:
```bash
cp .env.example .env
# Edit .env with your values
docker-compose up -d
```

---

## CI/CD Pipeline

File: `.github/workflows/ci-cd.yml`

```
git push to main
        ↓
Test Backend (Maven tests)
        ↓
Build & Push Docker Images → GHCR
  ghcr.io/medaminenj/kamka-assessment/backend:latest
  ghcr.io/medaminenj/kamka-assessment/frontend:latest
        ↓
Deploy to Render (via deploy hooks)
```

Pipeline stages:
- `test-backend` — runs Maven tests on every push
- `build-and-push` — builds Docker images, pushes to GitHub Container Registry
- `deploy` — triggers Render redeploy via webhook (main branch only)

---

## Dev vs Production Differences

| Aspect | Local (dev) | Render (prod) |
|--------|-------------|---------------|
| Database | MySQL 8 in Docker | PostgreSQL 15 managed |
| Frontend build | --configuration development (Dockerfile.dev) | --configuration production (Dockerfile) |
| Backend URL | http://localhost:8080 | https://noteflow-backend-tvn3.onrender.com |
| Secrets | .env file | Render dashboard variables |
| Monitoring | Prometheus + Grafana containers | /actuator/health + /actuator/prometheus |
| Compose file | docker-compose.yml | docker-compose.prod.yml (reference) |

---

## Monitoring & Health Checks

Every service exposes a health check:
- **Backend** → `/actuator/health` — Spring Boot Actuator, shows DB connection status
- **Frontend** → `/health` — Nginx returns `ok`
- **Database** → `mysqladmin ping` — configured in docker-compose healthcheck

Prometheus scrapes backend metrics every 10 seconds from `/actuator/prometheus`.

To view metrics in Grafana:
1. Open http://localhost:3000 (admin / admin123)
2. Connections → Data sources → Add Prometheus → URL: `http://prometheus:9090`
3. Dashboards → New dashboard → Add visualization
4. Select `prometheus` as data source → Metric: `jvm_memory_used_bytes` → Run queries

---

## Bash Scripts

**Deploy script**
```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```
Pulls latest images, restarts all containers, polls `/actuator/health` until UP, auto-rollbacks on failure.

**Database backup**
```bash
chmod +x scripts/backup.sh
./scripts/backup.sh
```
Exports MySQL database to `./backups/noteflow_TIMESTAMP.sql`, keeps last 7 backups, fails loudly on any error (`set -euo pipefail`).

---

## Production Deployment (Render)

The stack is deployed on Render free tier:
- **Frontend:** https://noteflow-frontend-hmf6.onrender.com
- **Backend:** https://noteflow-backend-tvn3.onrender.com
- **Database:** PostgreSQL on Render (Oregon region)

Required environment variables for backend on Render:
```
DATABASE_URL=jdbc:postgresql://<host>/<dbname>
DATABASE_USERNAME=<user>
DATABASE_PASSWORD=<password>
CORS_ALLOWED_ORIGINS=https://noteflow-frontend-hmf6.onrender.com
```

---

## Project Structure

```
kamka-assessment/
├── .github/workflows/
│   └── ci-cd.yml              # GitHub Actions pipeline
├── backend/
│   ├── src/                   # Spring Boot source
│   ├── Dockerfile             # Multi-stage build
│   └── pom.xml
├── frontend/
│   ├── src/                   # Angular source
│   ├── Dockerfile             # Production build (Render)
│   ├── Dockerfile.dev         # Development build (local)
│   └── nginx.conf             # Nginx config with health endpoint
├── monitoring/
│   └── prometheus.yml         # Prometheus scrape config
├── scripts/
│   ├── deploy.sh              # Deploy + health check + rollback
│   └── backup.sh              # Database backup with rotation
├── docker-compose.yml         # Local dev stack (MySQL)
├── docker-compose.prod.yml    # Production reference (PostgreSQL)
├── .env.example               # Secrets template
└── README.md
```
