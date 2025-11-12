#!/usr/bin/env bash
set -e
HALF_CPUS=$(python3 - <<'PY'
import os
n = os.cpu_count() or 1
print(max(1, n//2))
PY
)
export HOST_UID=$(id -u) HOST_GID=$(id -g) HALF_CPUS
docker compose up --build
