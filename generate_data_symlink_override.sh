#!/bin/bash

# This is used to create Docker compose override where
# `./data/` has symlinks that also need to be mounted
# within the Docker container.
# Currently used in the Ansible deployment.

# Base volumes for nginx service
echo "services:"
echo "  file-server:"
echo "    volumes:"
echo "      - ./data:/usr/share/nginx/html/data:ro"
echo "      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro"

# Find and resolve symlinks inside ./data
find ./data -type l | while read -r link; do
  target=$(readlink -f "$link")

  if [[ -e "$target" ]]; then
    echo "      - \"$target:$target:ro\""
  else
    echo "      # WARNING: Broken symlink: $link → $target" >&2
  fi
done
