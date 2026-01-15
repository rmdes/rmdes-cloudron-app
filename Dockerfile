FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c

RUN mkdir -p /app/code /app/pkg /app/data
WORKDIR /app/code

# Install Go 1.23
ARG GO_VERSION=1.23.4
RUN curl -L https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xzf - && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Install Hugo extended
ARG HUGO_VERSION=0.152.2
RUN curl -L https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - hugo

# Install Dart Sass
ARG DARTSASS_VERSION=1.83.4
RUN curl -L https://github.com/sass/dart-sass/releases/download/${DARTSASS_VERSION}/dart-sass-${DARTSASS_VERSION}-linux-x64.tar.gz | tar -C /usr/local -xzf - && \
    ln -s /usr/local/dart-sass/sass /usr/local/bin/sass

# Clone the application source
ARG APP_VERSION=main
RUN git clone --depth 1 --branch ${APP_VERSION} https://github.com/rmdes/rmdes-static-hugo.git /app/code && \
    rm -rf /app/code/.git

# Install Node dependencies
RUN npm ci --production=false

# Prepare PatternFly assets
RUN find node_modules/@patternfly/patternfly/ -name "*.css" -type f -delete && \
    rm -rf static/assets && \
    mkdir -p static/assets && \
    cp -r node_modules/@patternfly/patternfly/assets static/ && \
    cp -r node_modules/@fontsource/lato/files static/assets/fonts/lato && \
    mkdir -p static/assets/fonts/webfonts && \
    cp node_modules/@fortawesome/fontawesome-free/webfonts/fa-brands-400.woff2 static/assets/fonts/webfonts/

# Build Go binaries
RUN go build -o /app/pkg/ps-api ./cmd/ps-api && \
    go build -o /app/pkg/ps-gen-projects ./cmd/ps-gen-projects && \
    go build -o /app/pkg/ps-gen-starred ./cmd/ps-gen-starred && \
    go build -o /app/pkg/ps-proxy ./cmd/ps-proxy

# Copy startup files from packaging repo
COPY start.sh /app/pkg/start.sh
RUN chmod +x /app/pkg/start.sh

# Clean up build dependencies to reduce image size
RUN rm -rf /usr/local/go node_modules/.cache

# Set ownership at build time for faster startup
RUN chown -R cloudron:cloudron /app/code /app/pkg

CMD [ "/app/pkg/start.sh" ]
