# shellcheck shell=bash

# name|bundle_or_path_hint|risk_note
TRACKER_SPECS=(
  "Hubstaff|/Applications/Hubstaff.app|time tracking + screenshots"
  "Time Doctor|/Applications/Time Doctor*.app|time tracking"
  "RescueTime|/Applications/RescueTime.app|productivity tracking"
  "ActivTrak|ActivTrak|employee monitoring"
  "Teramind|Teramind|employee monitoring"
  "Veriato|Veriato|employee monitoring"
  "InterGuard|InterGuard|employee monitoring"
  "StaffCop|StaffCop|employee monitoring"
  "TeamViewer|/Applications/TeamViewer.app|remote desktop"
  "AnyDesk|/Applications/AnyDesk.app|remote desktop"
  "RustDesk|/Applications/RustDesk.app|remote desktop"
  "Chrome Remote Desktop|chrome-remote-desktop|remote desktop"
  "LogMeIn|/Applications/LogMeIn*.app|remote desktop"
  "Splashtop|/Applications/Splashtop*.app|remote desktop"
  "Screens Sharing|screensharingd|built-in VNC (if enabled)"
  "Microsoft Remote Desktop|/Applications/Microsoft Remote Desktop.app|remote desktop"
  "Zoom|/Applications/zoom.us.app|meetings (screen share when used)"
  "Loom|/Applications/Loom.app|screen recording"
  "OBS|/Applications/OBS.app|screen recording"
)

cmd_trackers() {
  local section=0
  [[ "${1:-}" == "--section" ]] && section=1
  if [[ "$section" -eq 0 ]]; then
    header "Trackers & remote access"
  fi

  local installed=0 running=0

  printf '  %-22s %-10s %-10s %s\n' "NAME" "INSTALLED" "RUNNING" "NOTE"
  printf '  %-22s %-10s %-10s %s\n' "----" "---------" "-------" "----"

  local spec name hint note inst run
  for spec in "${TRACKER_SPECS[@]}"; do
    IFS='|' read -r name hint note <<<"$spec"
    inst="no"
    run="no"

    # installed?
    if [[ "$hint" == /* ]]; then
      # path glob
      # shellcheck disable=SC2086
      if compgen -G "$hint" >/dev/null 2>&1; then
        inst="yes"
        installed=$((installed + 1))
      fi
    else
      if mdfind "kMDItemDisplayName == '*${name}*'c" 2>/dev/null | head -1 | grep -q .; then
        inst="yes"
        installed=$((installed + 1))
      else
        local app
        for app in /Applications/*; do
          [[ -e "$app" ]] || continue
          if [[ "$(basename "$app")" == *"$name"* ]]; then
            inst="yes"
            installed=$((installed + 1))
            break
          fi
        done
      fi
    fi

    # running?
    if pgrep -if "$name" >/dev/null 2>&1; then
      # reduce false positives: require path-ish match for common words
      case "$name" in
        Zoom)
          pgrep -if 'zoom.us|ZoomWorkplace' >/dev/null 2>&1 && run="yes" || run="no"
          ;;
        OBS)
          pgrep -if 'OBS Studio|obs-studio|OBS\.app' >/dev/null 2>&1 && run="yes" || true
          pgrep -x obs >/dev/null 2>&1 && run="yes" || true
          ;;
        *)
          run="yes"
          ;;
      esac
    fi
    # process name exact for hubstaff
    if [[ "$name" == "Hubstaff" ]] && pgrep -x Hubstaff >/dev/null 2>&1; then
      run="yes"
    fi
    if [[ "$run" == "yes" ]]; then
      running=$((running + 1))
    fi

    if [[ "$inst" == "yes" || "$run" == "yes" ]]; then
      if [[ "$run" == "yes" ]]; then
        printf '  %s%-22s %-10s %-10s %s%s\n' "$C_YELLOW" "$name" "$inst" "$run" "$note" "$C_RESET"
      else
        printf '  %-22s %-10s %-10s %s\n' "$name" "$inst" "$run" "$note"
      fi
    fi
  done

  echo
  kv "Installed (matched)" "$installed"
  kv "Running (matched)" "$running"

  if [[ "$running" -gt 0 ]]; then
    warn "  Running tools can collect or share session data per their design."
  else
    ok "  No matched trackers/remote tools currently running."
  fi
  info "  Hubstaff task-scoped control: see hubstaff-work-shell (hs stop / hs start)."
}
