# shellcheck shell=bash

cmd_tunnels() {
  local section=0
  [[ "${1:-}" == "--section" ]] && section=1
  if [[ "$section" -eq 0 ]]; then
    header "Tunnels & reverse proxies"
  fi

  local found=0

  _check_proc() {
    local name="$1"
    local hint="$2"
    if pgrep -x "$name" >/dev/null 2>&1 || pgrep -f "$name" >/dev/null 2>&1; then
      found=1
      bad "  RUNNING: $name — $hint"
      pgrep -lf "$name" 2>/dev/null | head -5 | sed 's/^/    /'
    fi
  }

  echo "  Processes:"
  _check_proc "cloudflared" "Cloudflare Tunnel — can expose local services"
  _check_proc "ngrok" "ngrok tunnel"
  _check_proc "frpc" "FRP client tunnel"
  _check_proc "bore" "bore tunnel"
  _check_proc "localtunnel" "localtunnel"
  _check_proc "pagekite" "pagekite"
  # clawdbot / similar gateways
  if pgrep -f "clawdbot" >/dev/null 2>&1; then
    found=1
    warn "  RUNNING: clawdbot (gateway) — review if intentional"
    pgrep -lf clawdbot 2>/dev/null | head -3 | sed 's/^/    /'
  fi

  if [[ "$found" -eq 0 ]]; then
    ok "  No well-known tunnel processes running."
  fi

  echo
  echo "  Launch configs (common paths):"
  local any_plist=0
  for p in \
    /Library/LaunchDaemons/com.cloudflare.cloudflared.plist \
    /Library/LaunchDaemons/com.cloudflare.cloudflared.plist.disabled \
    "$HOME/Library/LaunchAgents/com.cloudflared.tunnel.plist" \
    "$HOME/Library/LaunchAgents/com.cloudflared.tunnel.plist.disabled" \
    /Library/LaunchDaemons/*ngrok* \
    "$HOME/Library/LaunchAgents"/*ngrok* \
    /etc/cloudflared/config.yml \
    "$HOME/.cloudflared/config.yml"
  do
    # glob may expand empty
    for f in $p; do
      if [[ -e "$f" ]]; then
        any_plist=1
        warn "  present: $f"
        if [[ "$f" == *.yml || "$f" == *.yaml ]]; then
          # show hostname lines only, no tokens
          grep -E 'hostname:|service:|tunnel:' "$f" 2>/dev/null | sed 's/^/    /' || true
        fi
      fi
    done
  done
  if [[ "$any_plist" -eq 0 ]]; then
    ok "  No common tunnel configs found."
  fi

  echo
  info "  Tip: stop cloudflared with launchctl bootout + killall; revoke tokens in Cloudflare Zero Trust."
}
