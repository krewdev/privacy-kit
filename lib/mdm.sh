# shellcheck shell=bash

cmd_mdm() {
  local section=0
  [[ "${1:-}" == "--section" ]] && section=1
  if [[ "$section" -eq 0 ]]; then
    header "MDM / enrollment / device locks"
  fi

  echo "  Configuration profiles:"
  if have profiles; then
    local st
    st=$(profiles status 2>&1) || true
    echo "$st" | sed 's/^/    /'
    if echo "$st" | grep -qi 'no configuration profiles'; then
      ok "  No configuration profiles installed."
    else
      warn "  Profiles may be present — review: profiles list"
      profiles list 2>/dev/null | sed 's/^/    /' || true
    fi
  else
    warn "  profiles command not available"
  fi

  echo
  echo "  Managed Preferences:"
  if [[ -d "/Library/Managed Preferences" ]]; then
    warn "  /Library/Managed Preferences exists"
    ls "/Library/Managed Preferences" 2>/dev/null | sed 's/^/    /' | head -20
  else
    ok "  No /Library/Managed Preferences"
  fi

  echo
  echo "  MDM / enrollment hints:"
  if [[ -f /var/db/ConfigurationProfiles/Settings/.cloudConfigNoActivationRecord ]]; then
    ok "  No ADE/DEP cloud config activation record (personal-style)"
  fi
  if [[ -f /var/db/ConfigurationProfiles/Settings/com.apple.mdm.depnag.plist ]]; then
    info "  DEP nag plist present (often DEP state == 0 / disabled)"
  fi

  # mdmclient if present — may need root for full info
  if [[ -x /usr/libexec/mdmclient ]]; then
    if out=$(/usr/libexec/mdmclient QueryDeviceInformation 2>/dev/null); then
      echo "$out" | grep -E 'IsSupervised|IsActivationLockEnabled|MDMOptions|AwaitingConfiguration|DeviceName' | sed 's/^/    /' || true
    else
      info "  mdmclient QueryDeviceInformation needs elevated context for full detail"
    fi
  fi

  echo
  echo "  Activation / disk:"
  if fmm=$(defaults read /Library/Preferences/com.apple.FindMyMac FMMEnabled 2>/dev/null); then
    if [[ "$fmm" == "1" ]]; then
      kv "Find My Mac" "enabled (Activation Lock likely with Apple ID — personal, not MDM)"
    else
      kv "Find My Mac" "disabled"
    fi
  else
    kv "Find My Mac" "unknown"
  fi
  if have fdesetup; then
    kv "FileVault" "$(fdesetup status 2>/dev/null | tr -d '\n' || echo unknown)"
  fi
  if have csrutil; then
    kv "SIP" "$(csrutil status 2>/dev/null | tr -d '\n' || echo unknown)"
  fi

  echo
  echo "  Remote management prefs (legacy ARD):"
  if defaults read /Library/Preferences/com.apple.RemoteManagement >/dev/null 2>&1; then
    warn "  com.apple.RemoteManagement prefs exist"
    defaults read /Library/Preferences/com.apple.RemoteManagement 2>/dev/null | sed 's/^/    /' | head -15
    if launchctl print-disabled system 2>/dev/null | grep -q 'com.apple.screensharing" => disabled'; then
      ok "  Screen Sharing service is disabled"
    fi
  else
    ok "  No RemoteManagement prefs"
  fi

  echo
  echo "  Common enterprise agents:"
  local agents=(jamf falcon.agent SentinelAgent osqueryd kandji mosyle munki)
  local hit=0
  for a in "${agents[@]}"; do
    if pgrep -if "$a" >/dev/null 2>&1; then
      hit=1
      bad "  running: $a"
    fi
  done
  for path in \
    /usr/local/bin/jamf \
    /Library/Application\ Support/JAMF \
    /Library/Crowdstrike \
    /Applications/Falcon.app \
    /Library/Sentinel \
    /usr/local/bin/kandji
  do
    if [[ -e "$path" ]]; then
      hit=1
      warn "  present: $path"
    fi
  done
  if [[ "$hit" -eq 0 ]]; then
    ok "  No common Jamf/CrowdStrike/Sentinel/Kandji paths or processes found"
  fi
}
