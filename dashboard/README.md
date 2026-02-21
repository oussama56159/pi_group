# AeroCommand Dashboard

React/Vite single-page app for AeroCommand.

For the full project overview (backend, MQTT, edge agent, Kubernetes, CI/CD), see the repo root README.

## Run locally

```bash
cd dashboard
npm ci
npm run dev
```

Default URL: `http://localhost:3000`

## Environment variables

This app uses Vite env vars (see `.env.example`). Common ones:

- `VITE_API_BASE_URL` (e.g. `http://localhost:8000`)
- `VITE_WS_URL` (e.g. `ws://localhost:8000`)
- `VITE_MQTT_WS_URL` (e.g. `ws://localhost:8083/mqtt`)

## Build

```bash
cd dashboard
npm run build
```
