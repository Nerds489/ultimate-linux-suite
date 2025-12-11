#!/usr/bin/env bash
#
# logging.sh - Core logging functionality for Ultimate Linux Suite
#
# Provides timestamped logging with levels: DEBUG, INFO, WARN, ERROR
# Supports console output with colors and optional file logging
#

# Prevent multiple sourcing
[[ -n "${_LOGGING_SH_LOADED:-}" ]] && return 0
readonly _LOGGING_SH_LOADED=1

# Log level constants
declare -gr LOG_LEVEL_DEBUG=0
declare -gr LOG_LEVEL_INFO=1
declare -gr LOG_LEVEL_WARN=2
declare -gr LOG_LEVEL_ERROR=3

# Current log level (default: INFO)
declare -g CURRENT_LOG_LEVEL="${CURRENT_LOG_LEVEL:-$LOG_LEVEL_INFO}"

# Log file path (empty = no file logging)
declare -g LOG_FILE="${LOG_FILE:-}"

# Color support flag
declare -g USE_COLORS="${USE_COLORS:-1}"

# Color codes
declare -gr COLOR_RESET='\033[0m'
declare -gr COLOR_RED='\033[0;31m'
declare -gr COLOR_GREEN='\033[0;32m'
declare -gr COLOR_YELLOW='\033[0;33m'
declare -gr COLOR_BLUE='\033[0;34m'
declare -gr COLOR_CYAN='\033[0;36m'
declare -gr COLOR_GRAY='\033[0;90m'
declare -gr COLOR_BOLD='\033[1m'

# Initialize logging system
# Arguments:
#   $1 - Log file path (optional, empty for console only)
#   $2 - Log level (optional, default INFO)
logging_init() {
    local log_file="${1:-}"
    local level="${2:-$LOG_LEVEL_INFO}"

    if [[ -n "$log_file" ]]; then
        LOG_FILE="$log_file"
        local log_dir
        log_dir="$(dirname "$LOG_FILE")"
        if [[ ! -d "$log_dir" ]]; then
            mkdir -p "$log_dir" 2>/dev/null || {
                echo "Warning: Cannot create log directory $log_dir" >&2
                LOG_FILE=""
            }
        fi
        if [[ -n "$LOG_FILE" ]]; then
            : > "$LOG_FILE" 2>/dev/null || {
                echo "Warning: Cannot write to log file $LOG_FILE" >&2
                LOG_FILE=""
            }
        fi
    fi

    CURRENT_LOG_LEVEL="$level"

    # Detect color support
    if [[ ! -t 1 ]] || [[ "${NO_COLOR:-}" == "1" ]] || [[ "${TERM:-}" == "dumb" ]]; then
        USE_COLORS=0
    fi
}

# Get current timestamp for logging
_log_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Internal logging function
# Arguments:
#   $1 - Log level
#   $2 - Level name
#   $3 - Color code
#   $4... - Message
_log_message() {
    local level="$1"
    local level_name="$2"
    local color="$3"
    shift 3
    local message="$*"

    # Check if we should log at this level
    [[ "$level" -lt "$CURRENT_LOG_LEVEL" ]] && return 0

    local timestamp
    timestamp="$(_log_timestamp)"
    local formatted="[$timestamp] [$level_name] $message"

    # Console output
    if [[ "$USE_COLORS" -eq 1 ]]; then
        printf '%b[%s] [%b%s%b] %s%b\n' \
            "$COLOR_GRAY" "$timestamp" \
            "$color" "$level_name" "$COLOR_GRAY" \
            "$message" "$COLOR_RESET" >&2
    else
        echo "$formatted" >&2
    fi

    # File output (no colors)
    if [[ -n "$LOG_FILE" ]]; then
        echo "$formatted" >> "$LOG_FILE" 2>/dev/null
    fi
}

# Log debug message
log_debug() {
    _log_message "$LOG_LEVEL_DEBUG" "DEBUG" "$COLOR_CYAN" "$@"
}

# Log info message
log_info() {
    _log_message "$LOG_LEVEL_INFO" "INFO " "$COLOR_GREEN" "$@"
}

# Log warning message
log_warn() {
    _log_message "$LOG_LEVEL_WARN" "WARN " "$COLOR_YELLOW" "$@"
}

# Log error message
log_error() {
    _log_message "$LOG_LEVEL_ERROR" "ERROR" "$COLOR_RED" "$@"
}

# Log a section header (visual separator)
log_section() {
    local title="$1"
    local width=60
    local pad_char="─"
    local padding=""
    local title_len=${#title}
    local pad_len=$(( (width - title_len - 2) / 2 ))

    for ((i=0; i<pad_len; i++)); do
        padding+="$pad_char"
    done

    if [[ "$USE_COLORS" -eq 1 ]]; then
        printf '\n%b%s %s %s%b\n' "$COLOR_BOLD" "$padding" "$title" "$padding" "$COLOR_RESET" >&2
    else
        printf '\n%s %s %s\n' "$padding" "$title" "$padding" >&2
    fi
}

# Set log level
# Arguments:
#   $1 - Level (DEBUG, INFO, WARN, ERROR or numeric 0-3)
set_log_level() {
    local level="$1"
    case "${level^^}" in
        DEBUG|0) CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        INFO|1)  CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
        WARN|2)  CURRENT_LOG_LEVEL=$LOG_LEVEL_WARN ;;
        ERROR|3) CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        *)       log_warn "Unknown log level: $level" ;;
    esac
}

# Disable color output
disable_colors() {
    USE_COLORS=0
}

# Enable color output
enable_colors() {
    USE_COLORS=1
}
