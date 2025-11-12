#!/usr/bin/env bash
set -euo pipefail

# Roboczy podkatalog, unikamy klonowania do /work
mkdir -p /work/src
chown -R "$(id -u)":"$(id -g)" /work/src || true
cd /work/src

git config --global --add safe.directory /work/src/openwrt || true

if [ ! -d openwrt/.git ]; then
  [ -d openwrt ] && rm -rf openwrt
  git clone https://github.com/OpenMANET/openwrt.git openwrt
fi

cd openwrt
git fetch origin
git checkout mm/v23.05.5

./scripts/feeds update -a || true
./scripts/feeds install -a || true

BOARD="${BOARD:-ekh01}"
./scripts/morse_setup.sh -i -b "$BOARD"

make download
J="${BUILD_JOBS:-$(nproc)}"
make -j"$J" V=sc 2>&1 | tee /work/src/log.txt

