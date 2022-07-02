FROM ubuntu:jammy

LABEL \
  org.opencontainers.image.title="GitHub Mirror" \
  org.opencontainers.image.description="⤵️ A GitHub Action for mirroring a remote repository to the current repository." \
  org.opencontainers.image.url="https://github.com/bhcleek/github-mirror" \
  org.opencontainers.image.source="https://github.com/bhcleek/github-mirror" \
  org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache git openssh-client && \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

ADD *.sh /

ENTRYPOINT ["/entrypoint.sh"]
