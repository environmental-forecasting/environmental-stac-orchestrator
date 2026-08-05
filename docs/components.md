---
icon: lucide/boxes
---

# Components

This orchestrator manages three main components. Each component owns its documentation so changes land with the code.

## environmental-stac-generator

Converts forecast netCDF outputs to Cloud Optimized GeoTIFFs (COGs) and STAC catalogues, then ingests into pgSTAC.

- Repository / docs: [environmental-stac-generator](https://github.com/environmental-forecasting/environmental-stac-generator)
- Typical commands: `envstacgen preprocess`, `envstacgen ingest`

## environmental-stac-dashboard

Plotly Dash UI for visualising forecasts (tiles via TiTiler, catalogue via STAC API). Not intended as a standalone production deploy.

- Repository / docs: [environmental-stac-dashboard](https://github.com/environmental-forecasting/environmental-stac-dashboard)

## This orchestrator

Is the main high level meta repository which includes Docker Compose services (Traefik, PostgreSQL/pgSTAC, STAC FastAPI, file server, tiler, STAC Browser, landing page), env files, and optional Ansible playbooks.

- Repository: [environmental-stac-orchestrator](https://github.com/environmental-forecasting/environmental-stac-orchestrator)

## Example UIs

![STAC Browser](images/stac-browser-example.png)

![Dashboard (IceNet)](images/dashboard-icenet-example.png)
