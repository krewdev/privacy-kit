# shellcheck shell=bash
# Common helpers for pk

PK_JSON="${PK_JSON:-0}"
PK_COLOR="${PK_COLOR:-1}"

pk_init_colors() {
  if [[ ! -t 1 ]]; then
    PK_COLOR=0
  fi
  if [[ "${PK_COLOR}" == "1" ]]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_CYAN=$'\033[36m'
  else
    C_RESET=; C_BOLD=; C_DIM=; C_RED=; C_GREEN=; C_YELLOW=; C_CYAN=
  fi
}

pk_init_colors

die() { printf '%spk: %s%s\n' "$C_RED" "$*" "$C_RESET" >&2; exit 1; }
info() { printf '%s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
ok() { printf '%s%s%s\n' "$C_GREEN" "$*" "$C_RESET"; }
warn() { printf '%s%s%s\n' "$C_YELLOW" "$*" "$C_RESET"; }
bad() { printf '%s%s%s\n' "$C_RED" "$*" "$C_RESET"; }

header() {
  printf '\n%s══ %s ══%s\n' "$C_BOLD$C_CYAN" "$*" "$C_RESET"
}

section() {
  printf '\n%s▸ %s%s\n' "$C_BOLD" "$*" "$C_RESET"
}

kv() {
  printf '  %-28s %s\n' "$1" "$2"
}

is_flag() {
  # true if first remaining arg is --section (called as subsection of audit)
  [[ "${1:-}" == "--section" ]]
}

have() { command -v "$1" >/dev/null 2>&1; }
