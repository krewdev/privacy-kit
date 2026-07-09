# shellcheck shell=bash

cmd_launch() {
  local section=0
  [[ "${1:-}" == "--section" ]] && section=1
  if [[ "$section" -eq 0 ]]; then
    header "Launch agents & daemons"
  fi

  local interesting='cloudflare|cloudflared|ngrok|frp|tunnel|hubstaff|teamviewer|anydesk|logmein|vnc|remote|osquery|jamf|crowdstrike|sentinel|datadog|wireguard|vpn|zoom|docker|redis|ollama|clawdbot|keystone'

  _list_dir() {
    local dir="$1"
    local label="$2"
    echo "  $label ($dir):"
    if [[ ! -d "$dir" ]]; then
      info "    (missing)"
      return
    fi
    local f base
    local count=0
    local flagged=0
    # shellcheck disable=SC2012
    for f in "$dir"/*; do
      [[ -e "$f" ]] || continue
      base=$(basename "$f")
      [[ "$base" == *.plist || "$base" == *.plist.* || "$base" == *.disabled ]] || continue
      count=$((count + 1))
      if echo "$base" | grep -qiE "$interesting"; then
        flagged=$((flagged + 1))
        warn "    ★ $base"
      else
        # skip pure Apple in system dirs when many files
        if [[ "$dir" == /System/* ]]; then
          continue
        fi
        if [[ "$base" == com.apple.* ]]; then
          continue
        fi
        printf '    · %s\n' "$base"
      fi
    done
    if [[ "$count" -eq 0 ]]; then
      info "    (none)"
    elif [[ "$flagged" -gt 0 ]]; then
      info "    ($flagged flagged of non-empty listing)"
    fi
  }

  _list_dir "/Library/LaunchDaemons" "System LaunchDaemons"
  echo
  _list_dir "/Library/LaunchAgents" "System LaunchAgents"
  echo
  _list_dir "$HOME/Library/LaunchAgents" "User LaunchAgents"

  echo
  echo "  Login items (osascript):"
  if items=$(osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null); then
    if [[ -z "$items" || "$items" == "" ]]; then
      info "    (none)"
    else
      # comma-separated
      IFS=',' read -ra arr <<<"$items"
      for it in "${arr[@]}"; do
        it=$(echo "$it" | sed 's/^ *//;s/ *$//')
        printf '    · %s\n' "$it"
      done
    fi
  else
    warn "    (could not query)"
  fi

  echo
  info "  ★ = name matched remote access / tracker / tunnel heuristics"
  info "  Manage: System Settings → General → Login Items & Extensions"
}
