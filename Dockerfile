# Multi-stage build for minimal image size
# Based on https://github.com/IlyaVassyutovich/imapfilter/wiki/Docker

# Shared layer with dependencies
FROM alpine:3.21.3 AS base
RUN apk add --no-cache \
    lua5.4-dev \
    openssl-dev \
    pcre2-dev

# Build dependencies stage
FROM base AS build-deps
RUN apk add --no-cache \
    git \
    gcc \
    make \
    musl-dev

# Build stage
FROM build-deps AS build
WORKDIR /src
RUN git clone https://github.com/lefcha/imapfilter.git . && \
    make INCDIRS="-I/usr/include/lua5.4" LIBLUA="-llua5.4" && \
    make install

# Final stage - minimal runtime image
FROM alpine:3.21.3

# Install only runtime dependencies
RUN apk add --no-cache \
    lua5.4 \
    openssl \
    pcre2 \
    tzdata \
    ca-certificates \
    bash \
    && rm -rf /var/cache/apk/*

# Copy compiled imapfilter binary from build stage
COPY --from=build /usr/local/bin/imapfilter /usr/local/bin/imapfilter
COPY --from=build /usr/local/share/man/man1/imapfilter.1 /usr/local/share/man/man1/imapfilter.1
COPY --from=build /usr/local/share/man/man5/imapfilter_config.5 /usr/local/share/man/man5/imapfilter_config.5

# Create non-root user for security
RUN addgroup -g 1000 imapfilter && \
    adduser -D -u 1000 -G imapfilter imapfilter && \
    mkdir -p /config && \
    chown -R imapfilter:imapfilter /config

# Set working directory
WORKDIR /config

# Copy entrypoint script
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Switch to non-root user
USER imapfilter

# Environment variables
ENV RUN_INTERVAL=900 \
    RUN_MODE=daemon \
    TZ=Europe/Berlin \
    IMAPFILTER_CONFIG=/config/config.lua

# Health check
HEALTHCHECK --interval=5m --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep -f "imapfilter" >/dev/null || exit 1

# Use entrypoint for flexibility
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["imapfilter"]
