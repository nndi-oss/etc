FROM ubuntu:22.04

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
ENV NODE_VERSION 23.10.0
ENV GO_VERSION 1.24.2

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x64';; \
      ppc64el) ARCH='ppc64le';; \
      s390x) ARCH='s390x';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armv7l';; \
      i386) ARCH='x86';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && set -ex \
    # libatomic1 for arm
    && apt-get update && apt-get install -y ca-certificates curl wget g++ gcc git libc6-dev make pkg-config gnupg dirmngr xz-utils libatomic1 --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    #&& gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    #&& grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    #&& rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc \
    && apt-mark auto '.*' > /dev/null \
    && find /usr/local -type f -executable -exec ldd '{}' ';' \
      | awk '/=>/ { print $(NF-1) }' \
      | sort -u \
      | xargs -r dpkg-query --search \
      | cut -d: -f1 \
      | sort -u \
      | xargs -r apt-mark manual \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    # smoke tests
    && node --version \
    && npm --version \
    && npx playwright install-deps chromium

RUN echo "Playwright installed, installing v4"

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
      amd64) ARCH='x64';; \
      ppc64el) ARCH='ppc64le';; \
      s390x) ARCH='s390x';; \
      arm64) ARCH='arm64';; \
      armhf) ARCH='armv7l';; \
      i386) ARCH='x86';; \
      *) echo "unsupported architecture"; exit 1 ;; \
    esac \
   && rm -rf /usr/local/go \
   && url= \
   && case "${dpkgArch##*-}" in \
	amd64) \
      	url="https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz"; \
	;; \
	arm64) \
      	url="https://go.dev/dl/go$GO_VERSION.linux-arm64.tar.gz"; \
	;; \
      	i386) \
      	url="https://go.dev/dl/go$GO_VERSION.linux-386.tar.gz"; \
	;; \
	*) echo >&2 "error: unsupported architecture"; exit 1;; \
    esac \
    && curl -fsSL -o go.tgz --compressed "$url" \
    && tar -C /usr/local -xzf go.tgz \
    && export PATH="/usr/local/go/bin:$PATH" \
    && rm go.tgz

RUN git clone https://github.com/nndi-oss/v4 \
  && cd v4 \ 
  && git checkout feature/playwright-executor  \
  && /usr/local/go/bin/go build -o /usr/bin/v4 ./cmd/venom \
  && /usr/bin/v4 version
# Run a simple playwright based test to force v4 to download playwright dependencies
RUN cat > initial.yaml <<'EOF'
name: Initial v4 installation test
description: Tests playwright to ensure it installs
testcases:
- steps:
  - type: playwright
    url: https://google.com
    headless: true
    actions:
      - Goto "/" 
    assertions:
      - result.page.body ShouldContainSubstring Google
EOF

RUN /usr/bin/v4 run initial.yaml \ 
  && rm initial.yaml \
  && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false 

ENTRYPOINT [ "/usr/bin/v4" ]
CMD [ "run" ]

