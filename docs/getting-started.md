---
icon: lucide/rocket
---

# Getting started

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- Python 3.12+ and [uv](https://docs.astral.sh/uv/) (for docs and for installing the generator)

## Clone

```bash
git clone --recurse-submodules git@github.com:environmental-forecasting/environmental-stac-orchestrator.git
cd environmental-stac-orchestrator
```

## Configure environment

```bash
cp .env.template .env.dev
```

Edit `.env.dev` and set at least a real `DATABASE_PASSWORD`.

For local development that is usually enough. The stack is fronted by **Traefik**, a reverse proxy that routes browser paths such as `/dashboard/` and `/api` to the right container (on localhost for `make dev`).

For staging or production, copy the template to `.env.staging` or `.env.prod` instead and set:

| Variable | Meaning |
| -------- | ------- |
| `DOMAIN_NAME` | Public hostname users will open (e.g. `example.bas.ac.uk`). DNS for this name must point at the host. |
| `ACME_EMAIL` | Contact email for automated HTTPS certificates from Let's Encrypt (ACME is the certificate protocol Traefik uses). |
| `HOST_IP` | Optional. Host IP or hostname if people browse by that address as well as `DOMAIN_NAME`. |

Staging may also set `ACME_CASERVER` to Let's Encrypt's staging CA while testing certificates. See comments in `.env.template` and `compose.prod.yaml` for the full list.

## Start the stack

```bash
make dev          # detached; HTTP via Traefik on localhost
make dev attach   # Run in attached mode, where you have foreground logs
```

Stop with `make down dev`. Staging/production use `make staging` / `make prod` (HTTPS via `compose.prod.yaml`).

## Preprocess and ingest

Install and run the generator from its own repo (submodule):

```bash
cd environmental-stac-generator
pip install -e .
# or: uv sync && uv run ...

# Assuming following are run from the main Orchestrator repo path
# Optional: set the STAC collection name (default: default)
envstacgen preprocess <path_to_netcdf_predictions> -n <collection_name>
envstacgen ingest --env-file .env.dev data/stac/catalog.json -o
```

`-n` / `--name` names the collection under the root catalogue (outputs land in `data/cogs/<collection_name>/` and `data/stac/<collection_name>/`). Full CLI detail: [environmental-stac-generator](https://github.com/environmental-forecasting/environmental-stac-generator).

## Preview these docs

Locally (host uv, not Docker):

```bash
make docs-install
make docs
```

Then open http://127.0.0.1:8000.

With the Compose stack running, open `/docs/` on the same host as the landing
portal. That hub page links to the orchestrator, dashboard, and generator doc
sites. Submodule checkouts must be present so `Dockerfile.docs` can build them.
