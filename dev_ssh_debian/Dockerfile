# Pin the Debian (glibc) base directly. Home Assistant's newer "apps" builder
# ignores build.yaml's `build_from` and injects BUILD_FROM=ghcr.io/home-assistant
# /base:latest (Alpine/musl), which breaks `apt-get` and defeats the whole point
# of this add-on. Hardcoding FROM keeps the base Debian on every builder. The
# tag is multi-arch, so the correct arch is pulled automatically per build.
ARG BUILD_FROM=debian:bookworm-slim
FROM debian:bookworm-slim

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-server \
        jq \
        sudo \
        ca-certificates \
        curl \
        wget \
        git \
        nano \
        less \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/sshd

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]

LABEL \
    org.opencontainers.image.title="Dev SSH (Debian)" \
    org.opencontainers.image.description="glibc SSH target for Cursor / VS Code Remote-SSH" \
    org.opencontainers.image.source="https://github.com/elischleifer/hassio-addon-dev-ssh" \
    org.opencontainers.image.licenses="MIT"
