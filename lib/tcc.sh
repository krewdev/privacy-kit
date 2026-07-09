# shellcheck shell=bash

# auth_value: 0 denied, 1 unknown, 2 allowed (varies by macOS)
_tcc_label() {
  case "$1" in
    0) echo "denied" ;;
    1) echo "unknown" ;;
    2) echo "allowed" ;;
    3) echo "limited" ;;
    *) echo "auth=$1" ;;
  esac
}

_tcc_query() {
  local db="$1"
  local sql="
SELECT service, client, auth_value
FROM access
WHERE service IN (
  'kTCCServiceScreenCapture',
  'kTCCServiceAccessibility',
  'kTCCServiceListenEvent',
  'kTCCServicePostEvent',
  'kTCCServiceCamera',
  'kTCCServiceMicrophone',
  'kTCCServiceSystemPolicyAllFiles',
  'kTCCServiceSystemPolicySysAdminFiles'
)
AND auth_value != 0
ORDER BY service, client;
"
  if [[ ! -r "$db" ]]; then
    return 1
  fi
  if ! have sqlite3; then
    return 2
  fi
  sqlite3 -separator '|' "$db" "$sql" 2>/dev/null || return 1
}

_tcc_pretty_service() {
  case "$1" in
    kTCCServiceScreenCapture) echo "Screen Recording" ;;
    kTCCServiceAccessibility) echo "Accessibility" ;;
    kTCCServiceListenEvent) echo "Input Monitoring" ;;
    kTCCServicePostEvent) echo "Post Events" ;;
    kTCCServiceCamera) echo "Camera" ;;
    kTCCServiceMicrophone) echo "Microphone" ;;
    kTCCServiceSystemPolicyAllFiles) echo "Full Disk Access" ;;
    kTCCServiceSystemPolicySysAdminFiles) echo "System Admin Files" ;;
    *) echo "$1" ;;
  esac
}

cmd_tcc() {
  local section=0
  [[ "${1:-}" == "--section" ]] && section=1

  local user_db="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
  local sys_db="/Library/Application Support/com.apple.TCC/TCC.db"

  if [[ "$section" -eq 0 ]]; then
    header "TCC permissions"
  fi

  local service client auth label pretty
  local high_risk=0

  echo "  User TCC ($user_db):"
  if rows=$(_tcc_query "$user_db"); then
    if [[ -z "$rows" ]]; then
      info "    (no granted entries for watched services)"
    else
      while IFS='|' read -r service client auth; do
        [[ -z "$service" ]] && continue
        label=$(_tcc_label "$auth")
        pretty=$(_tcc_pretty_service "$service")
        printf '    %-20s %-40s %s\n' "$pretty" "$client" "$label"
        case "$service" in
          kTCCServiceScreenCapture|kTCCServiceAccessibility|kTCCServiceListenEvent|kTCCServiceSystemPolicyAllFiles)
            high_risk=1
            ;;
        esac
      done <<<"$rows"
    fi
  else
    warn "    (unreadable — normal under some SIP/privacy modes)"
  fi

  echo
  echo "  System TCC ($sys_db):"
  if rows=$(_tcc_query "$sys_db"); then
    if [[ -z "$rows" ]]; then
      info "    (no granted entries or empty)"
    else
      while IFS='|' read -r service client auth; do
        [[ -z "$service" ]] && continue
        label=$(_tcc_label "$auth")
        pretty=$(_tcc_pretty_service "$service")
        printf '    %-20s %-40s %s\n' "$pretty" "$client" "$label"
        case "$service" in
          kTCCServiceScreenCapture|kTCCServiceAccessibility|kTCCServiceListenEvent)
            case "$client" in
              *Hubstaff*|*hubstaff*|*TimeDoctor*|*RescueTime*|*TeamViewer*|*AnyDesk*|*netsoft*)
                bad "    ⚠ monitoring-related: $client → $pretty"
                high_risk=1
                ;;
            esac
            ;;
        esac
      done <<<"$rows"
    fi
  else
    warn "    (unreadable without Full Disk Access / root — try: tccutil or System Settings)"
  fi

  echo
  if [[ "$high_risk" -eq 1 ]]; then
    warn "  Review Screen Recording + Accessibility carefully (screenshot / keystroke class)."
  else
    ok "  No high-risk grants flagged by name heuristics (still review the list)."
  fi
  info "  Change: System Settings → Privacy & Security → Screen Recording / Accessibility / …"
}
