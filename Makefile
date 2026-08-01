.PHONY: attach build rebuild dev staging prod down clear-data clear-db clear-all

# Per-environment compose (separate names so they do not clash)
# --project-name: which running containers belong to this env (e.g. stac-dev-...)
# Volume name (POSTGRES_VOLUME_NAME in the env file): which database files to use
COMPOSE_dev     := docker compose --project-name stac-dev --env-file .env.development
COMPOSE_staging := docker compose --project-name stac-staging -f compose.yaml -f compose.prod.yaml --env-file .env.staging
COMPOSE_prod    := docker compose --project-name stac-prod -f compose.yaml -f compose.prod.yaml --env-file .env.production

ENV_FILE_dev     := .env.development
ENV_FILE_staging := .env.staging
ENV_FILE_prod    := .env.production

ENV := $(firstword $(filter dev staging prod,$(MAKECMDGOALS)))

# Runs in the background unless you add "attach", e.g. make dev attach
UP_FLAGS := $(if $(filter attach,$(MAKECMDGOALS)),,-d)

attach:
	@:

# Start an environment: make dev|staging|prod
# With down / clear-db / clear-all, this is only a name tag (nothing is started)
dev staging prod:
ifneq ($(filter down clear-db clear-all,$(MAKECMDGOALS)),)
	@:
else
	$(COMPOSE_$@) up $(UP_FLAGS)
endif

# Stop an environment, e.g. make down dev
# Usage: make down dev|staging|prod
down:
	$(if $(ENV),,$(error Usage: make down dev|staging|prod))
	$(COMPOSE_$(ENV)) down

build:
	docker compose --project-name stac-dev --env-file .env.development build

rebuild:
	docker compose --project-name stac-dev --env-file .env.development build --no-cache

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
