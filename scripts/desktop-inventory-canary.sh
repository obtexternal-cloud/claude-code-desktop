#!/bin/sh
set -eu

LOG_FILE="/tmp/claude-code-desktop-inventory-canary.log"
DESKTOP_DIR="${HOME}/Desktop"
STAMP="$(date -u '+%Y%m%dT%H%M%SZ')"
REPORT_FILE="${DESKTOP_DIR}/claude-code-desktop-inventory-canary-${STAMP}.txt"

log() {
  printf '%s %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >> "$LOG_FILE"
}

append_cmd() {
  label=$1
  shift
  {
    printf '\n[%s]\n' "$label"
    "$@" 2>&1 || printf 'command_failed status=%s\n' "$?"
  } >> "$REPORT_FILE"
}

: > "$LOG_FILE"
log "START desktop inventory canary"
log "uid=$(id -u) user=$(id -un)"

if [ ! -d "$DESKTOP_DIR" ]; then
  log "DESKTOP_MISSING path=$DESKTOP_DIR"
  printf 'desktop-inventory-canary failed; Desktop directory not found: %s\n' "$DESKTOP_DIR"
  exit 1
fi

if [ -e "$REPORT_FILE" ]; then
  log "REPORT_EXISTS refusing to overwrite path=$REPORT_FILE"
  printf 'desktop-inventory-canary failed; report already exists: %s\n' "$REPORT_FILE"
  exit 2
fi

{
  printf 'Claude Code Desktop Inventory Canary\n'
  printf 'Generated UTC: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf 'Purpose: Observe approval behavior for basic local metadata collection and Desktop write.\n'
} > "$REPORT_FILE"

append_cmd "whoami" id
append_cmd "uname" uname -a
append_cmd "hostname" hostname

if command -v sw_vers >/dev/null 2>&1; then
  append_cmd "macos_version" sw_vers
fi

if command -v sysctl >/dev/null 2>&1; then
  append_cmd "cpu_brand" sysctl -n machdep.cpu.brand_string
  append_cmd "hardware_model" sysctl -n hw.model
fi

if command -v claude >/dev/null 2>&1; then
  append_cmd "claude_version" claude --version
else
  {
    printf '\n[claude_version]\n'
    printf 'claude binary not found in PATH\n'
  } >> "$REPORT_FILE"
fi

append_cmd "desktop_permissions" ls -lde "$DESKTOP_DIR"
append_cmd "home_permissions" ls -lde "$HOME"
append_cmd "pwd" pwd

log "REPORT_CREATED path=$REPORT_FILE"
printf 'desktop-inventory-canary completed; report=%s log=%s\n' "$REPORT_FILE" "$LOG_FILE"
