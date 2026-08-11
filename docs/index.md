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

Each component also has its own docs site. On a running deployment, open
[/docs/](/docs/) for the documentation hub, then pick orchestrator, dashboard,
or generator.

## Quick links (live stack)

| Path (dev) | Service |
| ---------- | ------- |
| `/` | Landing portal |
| `/docs/` | Documentation hub |
| `/docs/orchestrator/` | Orchestrator docs |
| `/docs/dashboard/` | Dashboard docs |
| `/docs/generator/` | Generator docs |
| `/dashboard/` | Forecast dashboard |
| `/browser/` | STAC Browser |
| `/api` | STAC FastAPI |
| `/files/data/` | File server |
| `/tiles` | TiTiler |

Continue with [Getting started](getting-started.md).
