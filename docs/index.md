---
icon: lucide/house
---

# Environmental STAC Orchestrator

Meta-repository that coordinates deployment of a modular architecture for processing netCDF weather forecast predictions, cataloguing them with STAC, and serving them via databases, APIs, and a dashboard.

![Architecture diagram](images/orchestrator-services-dash-pgstac-leaflet-schematic.png)

## What this site covers

- Architecture and how services fit together
- Docker Compose / Traefik environments (`dev`, `staging`, `prod`)
- End-to-end bring-up (env files, preprocess, ingest)
- Ansible notes for Rocky 9 / VMware

Component CLI and UI detail live in their own docs (same PR as the code):

- [environmental-stac-generator](https://github.com/environmental-forecasting/environmental-stac-generator)
- [environmental-stac-dashboard](https://github.com/environmental-forecasting/environmental-stac-dashboard)

## Quick links

| Path (dev) | Service |
| ---------- | ------- |
| `/` | Landing portal |
| `/dashboard/` | Forecast dashboard |
| `/browser/` | STAC Browser |
| `/api` | STAC FastAPI |
| `/files/data/` | File server |
| `/tiles` | TiTiler |

Continue with [Getting started](getting-started.md).
