#!/bin/bash
set -e

# Color output for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Check if config file exists
if [ ! -f "${IMAPFILTER_CONFIG}" ]; then
    log_error "Configuration file not found: ${IMAPFILTER_CONFIG}"
    log_info "Please mount your config.lua file to ${IMAPFILTER_CONFIG}"
    log_info "Example: docker run -v /path/to/config.lua:/config/config.lua ..."
    exit 1
fi

log_info "imapfilter Docker Container started"
log_info "Configuration file: ${IMAPFILTER_CONFIG}"
log_info "Run mode: ${RUN_MODE}"
log_info "Timezone: ${TZ}"

# Function to run imapfilter
run_imapfilter() {
    log_info "Running imapfilter..."
    if imapfilter -c "${IMAPFILTER_CONFIG}" -v; then
        log_info "imapfilter completed successfully"
        return 0
    else
        log_error "imapfilter exited with error code $?"
        return 1
    fi
}

# Handle different run modes
case "${RUN_MODE}" in
    daemon)
        log_info "Starting in daemon mode with ${RUN_INTERVAL}s interval"
        while true; do
            run_imapfilter || log_warn "Continuing despite error..."
            log_info "Sleeping for ${RUN_INTERVAL} seconds..."
            sleep "${RUN_INTERVAL}"
        done
        ;;

    once)
        log_info "Running in one-shot mode"
        run_imapfilter
        exit $?
        ;;

    *)
        # Pass through any custom commands
        log_info "Running custom command: $@"
        exec "$@"
        ;;
esac
