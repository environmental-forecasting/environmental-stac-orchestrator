#!/bin/bash

## User-modifiable variables
## _________________________

# Domain name for HTTPS routing (only used in production mode)
DOMAIN_NAME=example.bas.ac.uk

# Email address for Let's Encrypt SSL certificate generation
# Required to receive expiration/security notices for the certificates
ACME_EMAIL=admin@example.bas.ac.uk
WORKERS=12

# Ports
STAC_FASTAPI_PORT=8000
FILE_SERVER_PORT=8001
TILER_PORT=8002
DATABASE_PORT=5432
DASHBOARD_PORT=80
STAC_BROWSER_PORT=81

# Database details
DATABASE_USER=stac
DATABASE_PASSWORD=stac
DATABASE_DBNAME=postgis

## Not to be changed (unless adding more env vars above)
## _____________________________________________________

# Parse command line arguments
MODE="dev"
while [[ $# -gt 0 ]]; do
  case $1 in
    --production)
      MODE="production"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: ./generate_env.sh [--production]"
      exit 1
      ;;
  esac
done

# Set host IP (LAN or external IP detection)
HOST_IP=$(hostname -I | awk '{print $1}')

# Generate URLs based on mode
if [ "$MODE" = "production" ]; then
  FILE_SERVER_URL="https://\${DOMAIN_NAME}/files"
  STAC_FASTAPI_URL="https://\${DOMAIN_NAME}/api"
  TILER_URL="https://\${DOMAIN_NAME}/tiles"
  echo "Generating .env for PRODUCTION (HTTPS via Traefik)"
else
  FILE_SERVER_URL="http://\${HOST_IP}:\${FILE_SERVER_PORT}"
  STAC_FASTAPI_URL="http://\${HOST_IP}:\${STAC_FASTAPI_PORT}"
  TILER_URL="http://\${HOST_IP}:\${TILER_PORT}"
  echo "Generating .env for DEVELOPMENT (HTTP, direct ports)"
fi

# Save config options
cat <<EOF > .env
# General config
# Mode: ${MODE}
HOST_IP=${HOST_IP}
DOMAIN_NAME=${DOMAIN_NAME}
ACME_EMAIL=${ACME_EMAIL}
WORKERS=${WORKERS}

# Ports
STAC_FASTAPI_PORT=${STAC_FASTAPI_PORT}
FILE_SERVER_PORT=${FILE_SERVER_PORT}
TILER_PORT=${TILER_PORT}
DATABASE_PORT=${DATABASE_PORT}
DASHBOARD_PORT=${DASHBOARD_PORT}
STAC_BROWSER_PORT=${STAC_BROWSER_PORT}

# Database config
DATABASE_USER=${DATABASE_USER}
DATABASE_PASSWORD=${DATABASE_PASSWORD}
DATABASE_DBNAME=${DATABASE_DBNAME}

# URLS
FILE_SERVER_URL=${FILE_SERVER_URL}
STAC_FASTAPI_URL=${STAC_FASTAPI_URL}
TILER_URL=${TILER_URL}
EOF

echo "Generated .env file (HOST_IP=${HOST_IP})"
