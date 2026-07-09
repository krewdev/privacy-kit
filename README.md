# privacy-kit

[![CI](https://github.com/krewdev/privacy-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/krewdev/privacy-kit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)](#requirements)

**Local privacy audits for macOS** — one CLI, no cloud, no spoofing.

`pk` answers: *What on this Mac can watch me, listen, tunnel out, or be managed by an org?*

It reads system state only (TCC databases when readable, launch agents, listeners, processes, profiles). Nothing is uploaded.

> **Not affiliated with Apple or any monitoring vendor.**  
> MIT licensed. For your own machines and authorized audits.

---

## Features

| Command | What you get |
|---------|----------------|
| `pk audit` | Full report (MDM → permissions → trackers → tunnels → listeners → launch items) |
| `pk tcc` | Screen Recording, Accessibility, Mic, Camera, Full Disk Access grants |
| `pk trackers` | Known time trackers & remote desktop apps (installed / running) |
| `pk tunnels` | cloudflared, ngrok, frp, similar + common config paths |
| `pk listeners` | TCP listen ports; highlights `*:port` (LAN-exposed) |
| `pk launch` | LaunchDaemons/Agents + login items; flags tunnel/tracker names |
| `pk mdm` | Profiles, Managed Preferences, Find My / FileVault / SIP, enterprise agents |
| `pk doctor` | Dependency check |

Companion: **[hubstaff-work-shell](https://github.com/krewdev/hubstaff-work-shell)** — start real Hubstaff only on a task; `hs stop` quits collection.

---

## Install (macOS)

```bash
git clone https://github.com/krewdev/privacy-kit.git
cd privacy-kit
./install.sh
source ~/.zshrc   # or open a new terminal
pk audit
```

Installs to `~/.local/share/privacy-kit` and symlinks `~/bin/pk`.

### Manual

```bash
git clone https://github.com/krewdev/privacy-kit.git ~/src/privacy-kit
mkdir -p ~/bin
ln -sfn ~/src/privacy-kit/bin/pk ~/bin/pk
export PATH="$HOME/bin:$PATH"
pk audit
```

---

## Quick start

```bash
pk audit              # full human report
pk trackers           # is Hubstaff / TeamViewer / … running?
pk tunnels            # any reverse tunnels?
pk listeners          # what’s bound on *:port?
pk tcc                # who has Screen Recording?
pk mdm                # enrolled in MDM?
pk audit --json       # short machine-readable summary
pk doctor
```

---

## Example output (abbreviated)

```text
══ Privacy Kit audit ══
▸ 1. MDM / device management
  No configuration profiles installed.
▸ 2. Sensitive permissions (TCC)
  Screen Recording    com.netsoft.Hubstaff    allowed
▸ 3. Known trackers / remote access apps
  Hubstaff            yes         no         time tracking + screenshots
▸ 4. Tunnels & reverse proxies
  No well-known tunnel processes running.
▸ 5. Network listeners
  ollama    3113   krewdev   *:11434
```

---

## Requirements

- macOS (tested on recent Apple Silicon; Intel should work)
- Standard tools: `bash`, `lsof`, `sqlite3`, `profiles` (usually present)
- **Optional:** Full Disk Access for Terminal if System TCC DB is unreadable

No Homebrew dependency. No network required for core audits.

---

## What this is not

- Not a fake tracker or “beat Hubstaff” tool  
- Not an MDM remover for supervised corporate devices  
- Not a guarantee of privacy — org policies while you *choose* to run software still apply  
- Not antivirus / EDR  

---

## Project layout

```text
privacy-kit/
  bin/pk           # entrypoint
  lib/*.sh         # audit modules
  docs/            # extra guides
  install.sh
  README.md
  LICENSE
```

---

## Development

```bash
make check          # shellcheck + smoke tests
make smoke
./bin/pk doctor
./bin/pk audit
```

| Target | What it runs |
|--------|----------------|
| `make check` | ShellCheck + smoke tests |
| `make smoke` | CLI surface without needing root |
| `make install` | Local install via `install.sh` |

CI runs the same checks on every push/PR ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)).

Bump `PK_VERSION` in `bin/pk` for releases.

---

## Related

- [hubstaff-work-shell](https://github.com/krewdev/hubstaff-work-shell) — start Hubstaff only on a task; `hs stop` quits collection  
- Apple: **System Settings → Privacy & Security**

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs for better status parsing, more tracker signatures, and Linux ports of *read-only* audits are welcome.

## Security

See [SECURITY.md](SECURITY.md). Never commit TCC dumps with sensitive org names if that matters to you; redact when filing issues.

## License

[MIT](LICENSE)
