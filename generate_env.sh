#!/bin/bash

# Get host IP (LAN or external IP detection)
WORKERS=12
TILER_PORT=8000
DASHBOARD_PORT=80
DATA_PORT=8002

# Save config options
cat <<EOF > .env
WORKERS=${WORKERS}
TILER_PORT=${TILER_PORT}
DASHBOARD_PORT=${DASHBOARD_PORT}
DATA_PORT=${DATA_PORT}
HOST_IP=<ENTER_HOST_IP>
EOF

sed -i.bak "s|<ENTER_HOST_IP>|$(hostname -I | awk '{print $1}')|g" .env

