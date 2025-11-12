FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8

RUN apt-get update && apt-get install -y \
    tzdata locales ca-certificates \
    build-essential clang flex bison g++ gawk \
    gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \
    python3-setuptools rsync swig unzip zlib1g-dev file wget \
  && rm -rf /var/lib/apt/lists/*

ARG UID=1000
ARG GID=1000

# jeśli GID istnieje – użyj go; jeśli nie – utwórz
RUN set -eux; \
    grpname="$(getent group ${GID} | cut -d: -f1 || true)"; \
    if [ -z "$grpname" ]; then grpname=builder; groupadd -g ${GID} "$grpname"; fi; \
    uid="${UID}"; \
    if getent passwd "${uid}" >/dev/null; then uid=1001; fi; \
    useradd -m -u "${uid}" -g "${grpname}" -s /bin/bash builder

WORKDIR /work
COPY build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh && chown -R builder:"$(getent group ${GID} | cut -d: -f1 || echo builder)" /work /usr/local/bin/build.sh

USER builder
ENV PATH="/home/builder/.local/bin:${PATH}"
ENTRYPOINT ["/usr/local/bin/build.sh"]

