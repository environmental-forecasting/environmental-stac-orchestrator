#!/bin/bash

# This is used to create Docker `compose.override.yaml`, when
# `./data/` has symlinks that also need to be mounted
# within the Docker container. Else, Docker will not be able to
# see the real paths of the symlinks in the nginx Docker service.
# Currently used in the Ansible deployment.

OUTPUT_FILE="compose.override.yaml"
DATA_DIR="./data"
# Location where data is mounted by nginx
CONTAINER_BASE="/usr/share/nginx/html/data"

VOLUME_ENTRIES=()

# Find and resolve symlinks inside ./data
while IFS= read -r link; do
  target=$(readlink -f "$link")
  name=$(basename "$link")

  if [[ -e "$target" ]]; then
    # Mount the symlink target to the expected path in container
    container_target="${CONTAINER_BASE}/${name}"
    VOLUME_ENTRIES+=("      - \"$target:$container_target:ro\"")
  else
    echo "Broken symlink: $link → $target" >&2
  fi
done < <(find "$DATA_DIR" -type l)

# Write compose override file if any symlinks are found
if (( ${#VOLUME_ENTRIES[@]} > 0 )); then
  {
    cat <<EOF
services:
  file-server:
    volumes:
EOF
    printf "%s\n" "${VOLUME_ENTRIES[@]}"
  } > "$OUTPUT_FILE"

  echo "Created $OUTPUT_FILE with ${#VOLUME_ENTRIES[@]} fixed symlink mounts."
else
  echo "No symlink targets found outside data directory. Override file not created."
fi
