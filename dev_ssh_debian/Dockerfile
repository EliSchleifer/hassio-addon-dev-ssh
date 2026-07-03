ARG BUILD_FROM
FROM ${BUILD_FROM}

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
