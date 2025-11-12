#!/usr/bin/env bash
set -e

if [ "${USE_ALL_CPUS:-0}" = "1" ]; then
  CPUS=$(python3 -c 'import os; print(os.cpu_count() or 1)')
else
  CPUS=$(python3 -c 'import os; n=os.cpu_count() or 1; print(max(1, n//2))')
fi

export HOST_UID=$(id -u) HOST_GID=$(id -g) HALF_CPUS=$CPUS
docker compose up --build
