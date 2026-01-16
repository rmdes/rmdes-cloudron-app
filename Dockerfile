# =============================================================================
# Build Stage - Contains all build tools, produces artifacts for runtime
# =============================================================================
FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c AS builder

WORKDIR /build

# Install Go 1.24
ARG GO_VERSION=1.24.1
RUN curl -L https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go

# Clone the application source
# Change CACHE_BUST value to force fresh clone (e.g., date or commit hash)
ARG CACHE_BUST=13
ARG APP_VERSION=main
RUN git clone --depth 1 --branch ${APP_VERSION} https://github.com/rmdes/rmdes-static-hugo.git /build/site && \
    rm -rf /build/site/.git

WORKDIR /build/site

# Install Node dependencies and prepare assets
RUN npm ci --production=false && \
    find node_modules/@patternfly/patternfly/ -name "*.css" -type f -delete && \
    rm -rf static/assets && \
    mkdir -p static/assets && \
    cp -r node_modules/@patternfly/patternfly/assets static/ && \
    cp -r node_modules/@fontsource/lato/files static/assets/fonts/lato && \
    mkdir -p static/assets/fonts/webfonts && \
    cp node_modules/@fortawesome/fontawesome-free/webfonts/fa-brands-400.woff2 static/assets/fonts/webfonts/ && \
    rm -rf node_modules

# Build Go binaries
RUN go build -o /build/bin/ps-api ./cmd/ps-api && \
    go build -o /build/bin/ps-gen-projects ./cmd/ps-gen-projects && \
    go build -o /build/bin/ps-gen-starred ./cmd/ps-gen-starred && \
    go build -o /build/bin/ps-proxy ./cmd/ps-proxy

# =============================================================================
# Runtime Stage - Minimal image with only what's needed to run
# =============================================================================
FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c

RUN mkdir -p /app/code /app/pkg /app/data

# Install Hugo extended (needed at runtime for server mode)
ARG HUGO_VERSION=0.152.2
RUN curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - hugo

# Install Dart Sass (needed at runtime for Hugo)
ARG DARTSASS_VERSION=1.83.4
RUN curl -L https://github.com/sass/dart-sass/releases/download/${DARTSASS_VERSION}/dart-sass-${DARTSASS_VERSION}-linux-x64.tar.gz | tar -C /usr/local -xzf - && \
    ln -s /usr/local/dart-sass/sass /usr/local/bin/sass

# Copy built artifacts from builder stage
COPY --from=builder /build/site /app/code
COPY --from=builder /build/bin/ /app/pkg/

# Copy startup script
COPY start.sh /app/pkg/start.sh

# Make all binaries executable and set ownership
RUN chmod +x /app/pkg/ps-* /app/pkg/start.sh && \
    chown -R cloudron:cloudron /app/code /app/pkg

CMD [ "/app/pkg/start.sh" ]
