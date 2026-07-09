# Interpreting results

## MDM

- **No configuration profiles** → not org-managed via Apple MDM profiles (common on personal Macs).
- **IsSupervised = 1** (if visible) → strongly managed device.
- **Find My / Activation Lock** → usually **your Apple ID**, not employer MDM.

## TCC (permissions)

| Permission | Risk |
|------------|------|
| Screen Recording | Can capture screen contents periodically or on demand |
| Accessibility | Can control UI / observe some input paths |
| Input Monitoring | Can see keystrokes (where granted) |
| Full Disk Access | Broad file read |
| Camera / Mic | Expected for Zoom/OBS; unexpected for random apps |

## Trackers

**Installed** ≠ currently collecting.  
**Running** + Screen Recording (for that app) ≈ can collect if its timer/policy is on.

## Tunnels

`cloudflared` / `ngrok` while running can expose local ports if configured.  
Configs under LaunchDaemons mean they may return after reboot until removed.

## Listeners

- `127.0.0.1` / `[::1]` → local only  
- `*:port` / `0.0.0.0` → other devices on your network may connect  

## False positives

Process name heuristics can match unrelated tools. Always verify path with `ps` / Activity Monitor.
