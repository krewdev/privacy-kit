# Contributing

## Rules

1. **Local audits only** — no telemetry, no phoning home.
2. **No spoofing** — do not add fake trackers, jigglers, or deceptive UI.
3. **Prefer read-only** — avoid destructive actions unless clearly opt-in (`pk fix` would need explicit confirmation).
4. Keep the stack **bash + macOS builtins** (optional `python3` for JSON only).

## Dev

```bash
./bin/pk doctor
./bin/pk audit
```

## Good PR targets

- More accurate tracker / tunnel signatures  
- Richer `--json` schema  
- Linux equivalents for listeners/processes  
- Tests with fixture process lists  

## Bad PR targets

- Bypassing MDM on supervised devices without owner consent framing  
- Keyloggers or “stealth” monitoring  
