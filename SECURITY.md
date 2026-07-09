# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 0.2.x   | Yes |
| 0.1.x   | Best-effort |

## What this project does

`pk` only reads local system state and prints reports. It does not open network connections by design (except whatever the OS tools you already have may do when invoked, e.g. none for core audits).

## Reporting a vulnerability

Please use **GitHub Security Advisories** (private) for this repository:

1. Open https://github.com/krewdev/privacy-kit/security/advisories/new  
2. Or: repository → **Security** → **Report a vulnerability**

Include:
- Affected version (`pk version`)
- macOS version
- Steps to reproduce
- Impact (e.g. unexpected file read, command injection)

Do **not** open a public issue for exploitable bugs until a fix is available.

## Out of scope

- Requests to spoof monitoring software or defeat employer policies while a timer is intentionally running  
- Bypassing OS TCC / SIP protections  
- Issues only in third-party apps (Hubstaff, Cloudflare, etc.)

## Data sensitivity

Audit output may include app bundle IDs, hostnames, and login item names. Treat shared reports as sensitive.
