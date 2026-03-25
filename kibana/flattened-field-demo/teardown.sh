#!/bin/bash
# Tear down the flattened field demo environment

echo "==> Stopping containers..."
docker compose down -v

echo "Done."
