# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker containerization project for [imapfilter](https://github.com/lefcha/imapfilter), a mail filtering utility that processes mailboxes according to Lua scripts. The project creates a lightweight (~20MB), multi-architecture Docker image that runs imapfilter in either daemon mode (continuous) or one-shot mode.

## Architecture

### Multi-Stage Docker Build

The Dockerfile uses a 4-stage build process:
1. **base**: Shared layer with runtime dependencies (lua5.4-dev, openssl-dev, pcre2-dev)
2. **build-deps**: Adds build tools (git, gcc, make, musl-dev)
3. **build**: Clones and compiles imapfilter from source
4. **final**: Minimal Alpine runtime with only necessary dependencies, running as non-root user

### Key Components

- **Dockerfile**: Multi-stage Alpine-based build supporting amd64, arm64, and arm/v7
- **docker-entrypoint.sh**: Bash script handling three run modes (daemon, once, custom) with colored logging
- **docker-compose.yml**: Example deployment configuration with health checks and resource limits
- **.github/workflows/docker-build.yml**: GitHub Actions workflow for automated multi-arch builds

### Runtime Behavior

The entrypoint script (docker-entrypoint.sh:1) determines execution mode:
- **daemon mode**: Runs imapfilter repeatedly at `RUN_INTERVAL` seconds (default: 900)
- **once mode**: Runs imapfilter once and exits
- **custom mode**: Passes through custom commands to imapfilter

Configuration is mounted at `/config/config.lua` (read-only recommended) and processed by the imapfilter binary compiled in the build stage.

## Development Commands

### Building the Image

Local single-architecture build:
```bash
docker build -t imapfilter:local .
```

Multi-architecture build (requires buildx):
```bash
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t imapfilter:multi .
```

### Testing

Test configuration in one-shot mode:
```bash
docker run --rm -e RUN_MODE=once -v $(pwd)/config.lua:/config/config.lua:ro imapfilter:local
```

Run with live logs:
```bash
docker compose up
```

Run in background:
```bash
docker compose up -d
docker logs -f imapfilter
```

### Deployment

Start container:
```bash
docker compose up -d
```

Stop container:
```bash
docker compose down
```

View logs:
```bash
docker logs -f imapfilter
```

Check health:
```bash
docker ps -a | grep imapfilter
docker inspect imapfilter
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RUN_MODE` | `daemon` | Execution mode: `daemon`, `once`, or custom |
| `RUN_INTERVAL` | `900` | Seconds between runs in daemon mode |
| `TZ` | `Europe/Berlin` | Container timezone |
| `IMAPFILTER_CONFIG` | `/config/config.lua` | Path to imapfilter configuration file |

## CI/CD Pipeline

The GitHub Actions workflow (.github/workflows/docker-build.yml:1) automatically:
- Triggers on push to main/master, tags starting with 'v', or PRs
- Sets up QEMU and Docker Buildx for multi-arch builds
- Builds for linux/amd64, linux/arm64, and linux/arm/v7
- Pushes to GitHub Container Registry (ghcr.io) with semantic versioning tags
- Uses GitHub Actions cache for faster builds

## Configuration Notes

- imapfilter configuration files are written in Lua and define IMAP accounts and filtering rules
- The container runs as user `imapfilter` (UID 1000, GID 1000) for security
- Config files should be mounted read-only (`:ro` flag) to prevent accidental modification
- The health check (Dockerfile:66) verifies imapfilter process is running every 5 minutes
