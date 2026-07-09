# shellcheck shell=bash

cmd_listeners() {
  local section=0
  [[ "${1:-}" == "--section" ]] && section=1
  if [[ "$section" -eq 0 ]]; then
    header "TCP listeners"
  fi

  if ! have lsof; then
    bad "  lsof not found"
    return 1
  fi

  # COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
  local lines
  if ! lines=$(lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null); then
    warn "  lsof failed (permissions?)"
    return 1
  fi

  echo "  Processes listening for inbound TCP:"
  echo
  printf '  %-12s %-7s %-18s %s\n' "COMMAND" "PID" "USER" "ADDRESS"
  printf '  %-12s %-7s %-18s %s\n' "------------" "-------" "------------------" "-------"

  local open_world=0
  local line cmd pid user addr
  # skip header
  while IFS= read -r line; do
    [[ "$line" == COMMAND* ]] && continue
    # parse carefully
    cmd=$(echo "$line" | awk '{print $1}')
    pid=$(echo "$line" | awk '{print $2}')
    user=$(echo "$line" | awk '{print $3}')
    addr=$(echo "$line" | awk '{print $9}')
    [[ -z "$cmd" ]] && continue

    # Flag binds on all interfaces
    if echo "$addr" | grep -qE '^\*:[0-9]+$|^0\.0\.0\.0:|^\[::\]:'; then
      open_world=1
      printf '  %s%-12s %-7s %-18s %s%s\n' "$C_YELLOW" "$cmd" "$pid" "$user" "$addr" "$C_RESET"
    elif echo "$addr" | grep -qE '^127\.|^\[::1\]:|^localhost'; then
      printf '  %-12s %-7s %-18s %s\n' "$cmd" "$pid" "$user" "$addr"
    else
      printf '  %-12s %-7s %-18s %s\n' "$cmd" "$pid" "$user" "$addr"
    fi
  done <<<"$lines"

  echo
  if [[ "$open_world" -eq 1 ]]; then
    warn "  Yellow rows bind on all interfaces (*:port) — reachable on LAN (or more if port-forwarded)."
    info "  Common: AirPlay 5000/7000, Ollama 11434, Redis, dev servers."
  else
    ok "  No all-interface listeners detected in this snapshot."
  fi
}
