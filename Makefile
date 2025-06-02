.PHONY: build rebuild up down

build:
	docker compose build

rebuild:
	docker compose down
	docker compose build --no-cache

up:
	docker compose up --build

down:
	docker compose down

