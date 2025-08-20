.PHONY: build rebuild up upbuild down clear-data clear-db clear-all

build:
	docker compose build

rebuild:
	docker compose down
	docker compose build --no-cache

up:
	docker compose up

upbuild:
	docker compose up --build

down:
	docker compose down

# Remove `./data` dir, and recreate it with `.gitkeep`
clear-data:
	bash -c '{ \
		read -p "This will remove the entire ./data directory. Are you sure? [y/N] " REPLY; \
		if [ "$$REPLY" = "y" ]; then \
			rm -rf ./data && \
			mkdir -p ./data && \
			touch ./data/.gitkeep && \
			echo "'./data' directory cleared and .gitkeep recreated."; \
		else \
			echo "Aborted."; \
		fi; \
	}'

# Removes the Docker volume used by pgSTAC if it exists.
# Make sure the volume is not being used (run `make down` first)
# or, will Error
clear-db:
	bash -c '{ \
		read -p "This will delete the Docker volume '\''environmental_pgstac_volume'\''. Are you sure? [y/N] " REPLY; \
		if [ "$$REPLY" = "y" ]; then \
			if docker volume inspect environmental_pgstac_volume > /dev/null 2>&1; then \
				docker volume rm environmental_pgstac_volume && \
				echo "Volume '\''environmental_pgstac_volume'\'' removed."; \
			else \
				echo "Volume '\''environmental_pgstac_volume'\'' does not exist. No action taken."; \
			fi; \
		else \
			echo "Aborted."; \
		fi; \
	}'

clear-all: clear-data clear-db
