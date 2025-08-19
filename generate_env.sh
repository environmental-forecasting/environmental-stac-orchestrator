#!/bin/bash

## User-modifiable variables
## _________________________

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

# Save config options
cat <<EOF > .env
# General config
HOST_IP=<ENTER_HOST_IP>
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
FILE_SERVER_URL=http://\${HOST_IP}:\${FILE_SERVER_PORT}
STAC_FASTAPI_URL=http://\${HOST_IP}:\${STAC_FASTAPI_PORT}
TILER_URL=http://\${HOST_IP}:\${TILER_PORT}
EOF

# Set host IP (LAN or external IP detection)
sed -i.bak "s|<ENTER_HOST_IP>|$(hostname -I | awk '{print $1}')|g" .env
