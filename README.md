Oczywiście — poniżej masz kompletną, przejrzystą instrukcję w formacie **Markdown**, gotową np. do README.md.

---

# 🔧 Instrukcja uruchomienia środowiska OpenMANET Builder (Ubuntu 24.04)

## 1️⃣ Instalacja Dockera i zależności

Wykonaj w terminalu:

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release apt-transport-https software-properties-common
```

Dodaj repozytorium Dockera:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Zainstaluj Dockera i Compose:

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Dodaj użytkownika do grupy `docker` i załaduj uprawnienia:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Sprawdź działanie:

```bash
docker --version
docker compose version
```

---

## 2️⃣ Przygotowanie katalogu projektu

W katalogu projektu (np. `~/openmanet-docker`):

```bash
mkdir -p ./work
sudo chown -R $(id -u):$(id -g) ./work
chmod -R u+rwX ./work
```

Ten krok zapewnia, że katalog `work` będzie tworzony i używany przez użytkownika `ubuntu`, a nie przez roota.

---

## 3️⃣ Pliki projektu

Upewnij się, że masz w folderze:

* `Dockerfile`
* `compose.yml`
* `build.sh`
* `up.sh`

---

### **compose.yml**

```yaml
services:
  openmanet-builder:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        UID: ${HOST_UID:-1000}
        GID: ${HOST_GID:-1000}
    user: "${HOST_UID:-1000}:${HOST_GID:-1000}"
    volumes:
      - ./work:/work
    working_dir: /work
    environment:
      - BOARD=${BOARD:-ekh01}
      - BUILD_JOBS=${BUILD_JOBS:-}
    cpus: ${HALF_CPUS:-1}
```

---

### **Dockerfile**

```dockerfile
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8

RUN apt-get update && apt-get install -y \
    tzdata locales ca-certificates \
    build-essential clang flex bison g++ gawk \
    gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \
    python3-setuptools rsync swig unzip zlib1g-dev file wget \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /work
COPY build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh

ENTRYPOINT ["/usr/local/bin/build.sh"]
```

---

### **build.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

mkdir -p /work/src
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
```

---

### **up.sh**

```bash
#!/usr/bin/env bash
set -e

if [ "${USE_ALL_CPUS:-0}" = "1" ]; then
  CPUS=$(python3 -c 'import os; print(os.cpu_count() or 1)')
else
  CPUS=$(python3 -c 'import os; n=os.cpu_count() or 1; print(max(1, n//2))')
fi

export HOST_UID=$(id -u) HOST_GID=$(id -g) HALF_CPUS=$CPUS
docker compose up --build
```

---

## 4️⃣ Uruchomienie

* Z połową rdzeni CPU:

  ```bash
  ./up.sh
  ```

* Z pełną mocą CPU:

  ```bash
  USE_ALL_CPUS=1 ./up.sh
  ```

---

## 5️⃣ Wynik kompilacji

Wyniki i logi znajdziesz w:

```
./work/src/log.txt
./work/src/openwrt/bin/
```

---

## 6️⃣ W razie błędów z uprawnieniami

Jeśli zobaczysz komunikaty o `Permission denied`, uruchom:

```bash
sudo chown -R $(id -u):$(id -g) ./work
```

lub usuń kontener i spróbuj ponownie:

```bash
docker compose down -v
./up.sh
```

---

To wszystko — środowisko powinno się poprawnie zbudować i rozpocząć kompilację OpenMANET/OpenWRT automatycznie.
