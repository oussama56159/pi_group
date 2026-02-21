# AeroCommand (PI Group)

AeroCommand is a cloud + edge platform for drone/robot fleet management.

## Repo layout

- `backend/` – FastAPI API gateway + service modules (auth, fleet, mission, telemetry, alert)
- `dashboard/` – React/Vite web UI
- `infra/` – Kubernetes manifests and Helm chart
- `shared_python/` – Shared Python library (schemas, MQTT topics, config, MAVLink defs)
- `edge-agent/` – Raspberry Pi edge agent (Pixhawk MAVLink ↔ cloud MQTT)

## High-level architecture

- **Dashboard** talks to **API** over HTTP/WebSocket.
- **API** talks to **datastores** (Postgres, MongoDB, Redis).
- **Edge Agent** connects to a Pixhawk via **MAVLink** and publishes telemetry to **MQTT (EMQX)**.
- **API** and **Dashboard** subscribe/stream telemetry and send commands via MQTT topics defined in `backend.shared.mqtt_topics.MQTTTopics`.

## Local development (Docker Compose)

Prereqs: Docker Desktop.

Start everything:

```bash
docker compose up -d --build
```

Or use the helper script (Windows):

```powershell
./scripts/start-dev.ps1
```

Default local endpoints:

- Dashboard: `http://localhost:3000`
- API: `http://localhost:8000` (health: `/health/live`, `/health/ready`)
- EMQX dashboard: `http://localhost:18083` (default user `admin`)
- Postgres: `localhost:5432`
- Mongo: `localhost:27017`
- Redis: `localhost:6379`

Stop:

```bash
docker compose down
```

Or use the helper script (Windows):

```powershell
./scripts/stop-dev.ps1
```

Restart:

```powershell
./scripts/restart-dev.ps1
```

## Local development (no Docker)

### Backend

Prereqs: Python 3.11.

```bash
cd backend
pip install -U pip
pip install fastapi[standard] uvicorn[standard] sqlalchemy[asyncio] asyncpg alembic \
  pydantic pydantic-settings python-jose[cryptography] passlib[bcrypt] motor redis[hiredis] \
  aiomqtt httpx python-multipart orjson

# run
uvicorn backend.services.gateway.main:app --reload --port 8000
```

### Dashboard

Prereqs: Node 20.

```bash
cd dashboard
npm ci
npm run dev
```

## Shared Python library

The shared library lives in `shared_python/` and is installable as `aerocommand-shared`.
It publishes modules under `backend.shared.*` so the backend and edge agent can share the same schemas/topics.

Install (dev):

```bash
pip install -e ./shared_python
```

## Edge agent (Raspberry Pi)

The edge agent is in `edge-agent/`.

Install (dev from repo root):

```bash
pip install -e ./shared_python
pip install -e ./edge-agent
```

Run:

```bash
# Example (adjust for your setup)
export ORG_ID="demo"
export VEHICLE_ID="vehicle-01"
export MAVLINK_CONNECTION="/dev/ttyAMA0"   # or udp:127.0.0.1:14550
export MAVLINK_BAUD="57600"
export MQTT_HOST="localhost"
export MQTT_PORT="1883"

# start
aerocommand-edge-agent
```

MQTT topics:

- Telemetry publish: `aerocommand/{org}/telemetry/{vehicle}/raw`
- Heartbeat publish: `aerocommand/{org}/telemetry/{vehicle}/heartbeat`
- Commands subscribe: `aerocommand/{org}/command/{vehicle}/request`
- Command ACK publish: `aerocommand/{org}/command/{vehicle}/ack`

## Production Docker Compose

Production Compose file: `docker-compose.prod.yml`.

```bash
# set required env vars (POSTGRES_*, MONGO_*, REDIS_PASSWORD, JWT_SECRET_KEY, etc.)
docker compose -f docker-compose.prod.yml up -d
```

## Kubernetes

### Raw manifests

Manifests are in `infra/k8s/`:

```bash
kubectl apply -f infra/k8s/namespace.yaml
kubectl apply -f infra/k8s/configmap.yaml
kubectl apply -f infra/k8s/secrets.yaml
kubectl apply -f infra/k8s/databases.yaml
kubectl apply -f infra/k8s/emqx.yaml
kubectl apply -f infra/k8s/api-server.yaml
kubectl apply -f infra/k8s/dashboard.yaml
kubectl apply -f infra/k8s/ingress.yaml
```

### Helm

Chart: `infra/helm/aerocommand/`.

```bash
helm upgrade --install aerocommand ./infra/helm/aerocommand \
  --namespace aerocommand --create-namespace \
  --values ./infra/helm/aerocommand/values.yaml
```

## CI/CD (GitHub Actions)

Workflows:

- `.github/workflows/ci.yml` – lint/test/build + build/push Docker images to GHCR
- `.github/workflows/cd.yml` – deploy (staging via `kubectl set image`, prod via Helm)

Recommended setup:

- Use GitHub **Environments**: `staging`, `production`
- Store kubeconfigs as secrets:
  - `KUBE_CONFIG_STAGING` (base64 kubeconfig)
  - `KUBE_CONFIG_PROD` (base64 kubeconfig)
- Store environment URLs as variables:
  - `STAGING_API_URL`
  - `PROD_API_URL`

## Secrets management

- Local dev: values in `docker-compose.yml` are dev-only.
- Kubernetes: `infra/k8s/secrets.yaml` contains placeholder base64 values.
  Use one of:
  - External Secrets Operator
  - Sealed Secrets
  - Your cloud secret manager + CSI driver

  ## Beginner setup (first time)

  This section is a step-by-step guide to get the platform running and create your first account.

  ### Option A: Docker (recommended)

  1) Prereqs
    - Install Docker Desktop.

  2) Start the stack

  ```bash
  docker compose up -d --build
  ```

  3) Open the dashboard
    - http://localhost:3000

  4) First account (dev auto-seed)
    - Email: owner@makerskills.com
    - Password: makerskills_owner_change_me

  5) Verify the API is healthy
    - http://localhost:8000/health/live
    - http://localhost:8000/health/ready

  6) Optional: turn Mock Mode off
    - Open the user menu in the top-right of the dashboard.
    - Toggle Mock Mode OFF to use the real backend.

  ### Option B: Local (no Docker)

  1) Prereqs
    - Python 3.11
    - Node 20
    - Postgres, MongoDB, Redis, and EMQX running locally

  2) Backend

  ```bash
  cd backend
  pip install -U pip
  pip install fastapi[standard] uvicorn[standard] sqlalchemy[asyncio] asyncpg alembic \
    pydantic pydantic-settings python-jose[cryptography] passlib[bcrypt] motor redis[hiredis] \
    aiomqtt httpx python-multipart orjson

  uvicorn backend.services.gateway.main:app --reload --port 8000
  ```

  3) Dashboard

  ```bash
  cd dashboard
  npm ci
  npm run dev
  ```

  4) Open the dashboard
    - http://localhost:5173

  5) First account (dev auto-seed)
    - Email: owner@makerskills.com
    - Password: makerskills_owner_change_me

  ### Change the default dev owner (optional)

  Set these environment variables for the API service:

  - OWNER_EMAIL
  - OWNER_PASSWORD
  - OWNER_NAME
  - OWNER_CREATE_ORG
  - OWNER_ORG_NAME
  - OWNER_ORG_SLUG

  For Docker, add them under the api-server environment section in docker-compose.yml.

  ### Common issues

  - Login fails with 401:
    - Ensure the dev owner exists (restart the API after setting env vars).
    - Make sure Mock Mode is OFF when you want real backend mode.

  - Dashboard shows Network Error:
    - Check that the API is running at http://localhost:8000.
    - Check CORS origins in docker-compose.yml include http://localhost:3000 or http://localhost:5173.
    - Verify the login request succeeds and a token is stored.

  ## Security-first onboarding model

  This project now follows an owner-first onboarding flow:

  - Public registration is disabled.
  - A single owner account is seeded at startup (env-driven).
  - Owner creates the first organization.
  - Owner/Admin creates all other users.

  ### Default owner (dev)

  - Email: `owner@makerskills.com`
  - Password: `makerskills_owner_change_me`

  Change these via `docker-compose.yml` under `api-server.environment`:

  - `OWNER_EMAIL`
  - `OWNER_PASSWORD`
  - `OWNER_NAME`
  - `OWNER_CREATE_ORG`
  - `OWNER_ORG_NAME`
  - `OWNER_ORG_SLUG`

  ### Onboarding flow

  1) Login as owner.
  2) Create first organization:
    - `POST /api/v1/auth/organizations`
    - Body: `{ "name": "AeroCommand HQ", "slug": "aerocommand" }`
  3) Create admins/operators:
    - `POST /api/v1/auth/users`
  4) Users login and operate normally.
