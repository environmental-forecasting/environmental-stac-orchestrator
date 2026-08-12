.PHONY: attach build rebuild certs letsencrypt dev staging prod down clear-data clear-db clear-all docs-install docs docs-build

# Per-environment compose (separate names so they do not clash)
# --project-name: which running containers belong to this env (e.g. stac-dev-...)
# Volume name (POSTGRES_VOLUME_NAME in the env file): which database files to use
# compose.data-symlinks.yaml is generated for resolved ./data mounts (Ansible).
DATA_LINKS := $(wildcard compose.data-symlinks.yaml)
COMPOSE_FILES_dev     := -f compose.yaml -f compose.override.yaml $(if $(DATA_LINKS),-f compose.data-symlinks.yaml)
COMPOSE_FILES_staging := -f compose.yaml -f compose.prod.yaml $(if $(DATA_LINKS),-f compose.data-symlinks.yaml)
COMPOSE_FILES_prod    := -f compose.yaml -f compose.prod.yaml $(if $(DATA_LINKS),-f compose.data-symlinks.yaml)
COMPOSE_dev     := docker compose --project-name stac-dev $(COMPOSE_FILES_dev) --env-file .env.development
COMPOSE_staging := docker compose --project-name stac-staging $(COMPOSE_FILES_staging) --env-file .env.staging
COMPOSE_prod    := docker compose --project-name stac-prod $(COMPOSE_FILES_prod) --env-file .env.production

ENV_FILE_dev     := .env.development
ENV_FILE_staging := .env.staging
ENV_FILE_prod    := .env.production

ENV := $(firstword $(filter dev staging prod,$(MAKECMDGOALS)))

# Runs in the background unless you add "attach", e.g. make dev attach
# COMPOSE_UP_EXTRA can add --build --pull always (Ansible deploy).
UP_FLAGS := $(if $(filter attach,$(MAKECMDGOALS)),,-d) $(COMPOSE_UP_EXTRA)

attach:
	@:

# Self-signed TLS material for Traefik (compose.override.yaml / ACME fallback).
# Optional CERT_HOST=ip.or.dns adds that name to the SAN. Regenerates if that
# host is missing from an existing cert (wrong first deploy).
certs:
	@mkdir -p certs
	@need=0; \
	if [ ! -f certs/dev.crt ] || [ ! -f certs/dev.key ]; then \
		need=1; \
	elif [ -n "$(CERT_HOST)" ] && ! openssl x509 -noout -text -in certs/dev.crt | grep -qF "$(CERT_HOST)"; then \
		need=1; \
	fi; \
	if [ "$$need" = 1 ]; then \
		san="DNS:localhost,IP:127.0.0.1,IP:0:0:0:0:0:0:0:1"; \
		if [ -n "$(CERT_HOST)" ]; then \
			case "$(CERT_HOST)" in \
				*[!0-9.]*) san="$$san,DNS:$(CERT_HOST)" ;; \
				*) san="$$san,IP:$(CERT_HOST)" ;; \
			esac; \
		fi; \
		openssl req -x509 -nodes -newkey rsa:2048 \
			-keyout certs/dev.key -out certs/dev.crt -days 825 \
			-subj "/CN=$(or $(CERT_HOST),localhost)" \
			-addext "subjectAltName=$$san"; \
		echo "Generated certs/dev.crt and certs/dev.key"; \
	fi

# Traefik ACME storage (staging/prod). Keeps an existing acme.json.
letsencrypt:
	@mkdir -p letsencrypt
	@touch letsencrypt/acme.json
	@chmod 600 letsencrypt/acme.json

# Start an environment: make dev|staging|prod
# With down / build / rebuild / clear-db / clear-all, this is only a name tag
# (nothing is started).
dev staging prod:
ifneq ($(filter down build rebuild clear-db clear-all,$(MAKECMDGOALS)),)
	@:
else
	@$(MAKE) certs
	@if [ "$@" != dev ]; then $(MAKE) letsencrypt; fi
	$(COMPOSE_$@) up $(UP_FLAGS)
endif

# Stop an environment, e.g. make down dev
# Usage: make down dev|staging|prod
down:
	$(if $(ENV),,$(error Usage: make down dev|staging|prod))
	$(COMPOSE_$(ENV)) down $(DOWN_FLAGS)

# Build images for an environment, e.g. make build dev
# Usage: make build|rebuild dev|staging|prod
build:
	$(if $(ENV),,$(error Usage: make build dev|staging|prod))
	$(COMPOSE_$(ENV)) build

rebuild:
	$(if $(ENV),,$(error Usage: make rebuild dev|staging|prod))
	$(COMPOSE_$(ENV)) build --no-cache

confirm = read -p "$(1) [y/N] " r; [ "$$r" = y ] || { echo Aborted.; exit 1; }

# Delete generated forecast files under ./data
clear-data:
	@$(call confirm,Remove the entire ./data directory?)
	rm -rf ./data && mkdir -p ./data && touch ./data/.gitkeep

# Wipe the database for one environment, e.g. make clear-db dev
# Usage: make clear-db dev|staging|prod
clear-db:
	$(if $(ENV),,$(error Usage: make clear-db dev|staging|prod))
	@$(call confirm,Delete Postgres volume for $(ENV)?)
	@vol=$$(grep -E '^POSTGRES_VOLUME_NAME=' $(ENV_FILE_$(ENV)) | cut -d= -f2-); \
	if [ -z "$$vol" ]; then echo "POSTGRES_VOLUME_NAME not set in $(ENV_FILE_$(ENV))"; exit 1; fi; \
	docker volume rm "$$vol"

# Delete ./data and wipe that environment's database, e.g. make clear-all dev
# Usage: make clear-all dev|staging|prod
clear-all:
	$(if $(ENV),,$(error Usage: make clear-all dev|staging|prod))
	@$(MAKE) clear-data
	@$(MAKE) clear-db $(ENV)

# Documentation
docs-install:
	uv sync --group docs --no-install-project

docs:
	uv run --group docs zensical serve

docs-build:
	uv run --group docs zensical build
