# Security

`pk` only reads local state and prints reports. It does not open network connections by design.

## Reporting

Report vulnerabilities in this repo’s scripts (e.g. unsafe command injection) via GitHub issues (redact secrets) or a private channel if available.

## Data sensitivity

Audit output may include app bundle IDs and hostnames. Treat reports as sensitive if shared.

## Permissions

Reading `/Library/Application Support/com.apple.TCC/TCC.db` may require Full Disk Access for your terminal. That is an OS restriction, not a bug to “bypass.”
