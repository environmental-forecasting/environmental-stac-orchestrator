---
icon: lucide/boxes
---

# Components

This orchestrator manages three main components. Each component owns its documentation so changes land with the code.

On a running deployment, the [/docs/](/docs/) hub links to each docs site.

## environmental-stac-generator

Converts forecast netCDF outputs to Cloud Optimized GeoTIFFs (COGs) and STAC catalogues, then ingests into pgSTAC.

- Docs: [/docs/generator/](/docs/generator/)
- Repository: [environmental-stac-generator](https://github.com/environmental-forecasting/environmental-stac-generator)
- Typical commands: `envstacgen preprocess`, `envstacgen ingest`

## environmental-stac-dashboard

Plotly Dash UI for visualising forecasts (tiles via TiTiler, catalogue via STAC API). Not intended as a standalone production deploy.

- Docs: [/docs/dashboard/](/docs/dashboard/)
- Repository: [environmental-stac-dashboard](https://github.com/environmental-forecasting/environmental-stac-dashboard)

## This orchestrator

Is the main high level meta repository which includes Docker Compose services (Traefik, PostgreSQL/pgSTAC, STAC FastAPI, file server, tiler, STAC Browser, landing page, docs), env files, and optional Ansible playbooks.

- Docs: [/docs/orchestrator/](/docs/orchestrator/)
- Repository: [environmental-stac-orchestrator](https://github.com/environmental-forecasting/environmental-stac-orchestrator)

## Example UIs

![STAC Browser](images/stac-browser-example.png)

![Dashboard (IceNet)](images/dashboard-icenet-example.png)
