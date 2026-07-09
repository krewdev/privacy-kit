#!/usr/bin/env bash
# Smoke tests — no macOS-only features required for core CLI surface.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PK="$ROOT/bin/pk"
fail=0

pass() { printf '  PASS  %s\n' "$*"; }
fail_() { printf '  FAIL  %s\n' "$*"; fail=1; }

echo "privacy-kit smoke tests"
[[ -x "$PK" ]] || chmod +x "$PK"

# help / version
out=$("$PK" version)
echo "$out" | grep -q 'pk 0\.' && pass "version" || fail_ "version: $out"

out=$("$PK" help)
echo "$out" | grep -qi 'audit' && pass "help mentions audit" || fail_ "help"

out=$("$PK" doctor 2>&1) || true
echo "$out" | grep -qi 'pk version' && pass "doctor" || fail_ "doctor: $out"

# unknown command exits non-zero
if "$PK" not-a-real-command >/dev/null 2>&1; then
  fail_ "unknown command should fail"
else
  pass "unknown command fails"
fi

# scripts are valid bash -n
bash -n "$PK" && pass "bash -n bin/pk" || fail_ "bash -n bin/pk"
for f in "$ROOT"/lib/*.sh; do
  bash -n "$f" && pass "bash -n $(basename "$f")" || fail_ "bash -n $f"
done
bash -n "$ROOT/install.sh" && pass "bash -n install.sh" || fail_ "install.sh"

# install.sh is not destructive without run — just syntax checked above

if [[ "$fail" -ne 0 ]]; then
  echo "FAILED"
  exit 1
fi
echo "OK"
