#!/usr/bin/env python3
"""Structured JSON audit collector for pk. Local-only, no network."""
from __future__ import annotations

import json
import os
import re
import sqlite3
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def sh(cmd: str) -> str:
    try:
        return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL).strip()
    except subprocess.CalledProcessError:
        return ""


def sh_ok(cmd: str) -> bool:
    try:
        subprocess.check_call(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False


def pgrep_x(name: str) -> bool:
    return sh_ok(f"pgrep -x {name}")


def pgrep_f(pattern: str) -> bool:
    return sh_ok(f"pgrep -f {pattern}")


TCC_SERVICES = {
    "kTCCServiceScreenCapture": "screen_recording",
    "kTCCServiceAccessibility": "accessibility",
    "kTCCServiceListenEvent": "input_monitoring",
    "kTCCServicePostEvent": "post_events",
    "kTCCServiceCamera": "camera",
    "kTCCServiceMicrophone": "microphone",
    "kTCCServiceSystemPolicyAllFiles": "full_disk_access",
    "kTCCServiceSystemPolicySysAdminFiles": "system_admin_files",
}

AUTH_LABEL = {0: "denied", 1: "unknown", 2: "allowed", 3: "limited"}

MONITORING_HINTS = re.compile(
    r"hubstaff|netsoft|timedoctor|rescuetime|teamviewer|anydesk|activtrak|teramind",
    re.I,
)


def collect_tcc(db_path: Path) -> dict[str, Any]:
    out: dict[str, Any] = {"path": str(db_path), "readable": False, "entries": []}
    if not db_path.is_file():
        out["error"] = "missing"
        return out
    if not os.access(db_path, os.R_OK):
        out["error"] = "unreadable"
        return out
    try:
        con = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
        cur = con.cursor()
        placeholders = ",".join("?" * len(TCC_SERVICES))
        cur.execute(
            f"""
            SELECT service, client, auth_value FROM access
            WHERE service IN ({placeholders}) AND auth_value != 0
            ORDER BY service, client
            """,
            list(TCC_SERVICES.keys()),
        )
        for service, client, auth in cur.fetchall():
            entry = {
                "service": service,
                "service_label": TCC_SERVICES.get(service, service),
                "client": client,
                "auth_value": auth,
                "auth": AUTH_LABEL.get(auth, str(auth)),
                "monitoring_hint": bool(MONITORING_HINTS.search(client or "")),
            }
            out["entries"].append(entry)
        con.close()
        out["readable"] = True
    except Exception as e:  # noqa: BLE001 — report any DB failure
        out["error"] = str(e)
    return out


TRACKERS = [
    ("Hubstaff", "Hubstaff", "/Applications/Hubstaff.app"),
    ("Time Doctor", "Time Doctor", None),
    ("RescueTime", "RescueTime", "/Applications/RescueTime.app"),
    ("TeamViewer", "TeamViewer", "/Applications/TeamViewer.app"),
    ("AnyDesk", "AnyDesk", "/Applications/AnyDesk.app"),
    ("RustDesk", "RustDesk", "/Applications/RustDesk.app"),
    ("Loom", "Loom", "/Applications/Loom.app"),
    ("OBS", r"OBS|obs-studio", "/Applications/OBS.app"),
    ("Zoom", r"zoom\.us|ZoomWorkplace", "/Applications/zoom.us.app"),
]


def collect_trackers() -> list[dict[str, Any]]:
    rows = []
    apps = list(Path("/Applications").glob("*")) if Path("/Applications").is_dir() else []
    for name, proc_pat, path in TRACKERS:
        installed = False
        if path and Path(path).exists():
            installed = True
        else:
            for a in apps:
                if name.lower() in a.name.lower():
                    installed = True
                    break
        running = False
        if name == "Hubstaff":
            running = pgrep_x("Hubstaff")
        elif name == "Zoom":
            running = pgrep_f(r"zoom\.us|ZoomWorkplace")
        elif " " in name:
            try:
                out = subprocess.check_output(["pgrep", "-lf", name], text=True, stderr=subprocess.DEVNULL)
                running = name.lower() in out.lower()
            except subprocess.CalledProcessError:
                running = False
        else:
            running = pgrep_x(name) or pgrep_f(proc_pat)
        if installed or running:
            rows.append({"name": name, "installed": installed, "running": running})
    return rows


def collect_tunnels() -> dict[str, Any]:
    procs = {
        "cloudflared": pgrep_x("cloudflared"),
        "ngrok": pgrep_x("ngrok"),
        "frpc": pgrep_x("frpc"),
        "clawdbot": pgrep_f("clawdbot"),
    }
    configs = []
    for p in [
        "/Library/LaunchDaemons/com.cloudflare.cloudflared.plist",
        "/Library/LaunchDaemons/com.cloudflare.cloudflared.plist.disabled",
        str(Path.home() / "Library/LaunchAgents/com.cloudflared.tunnel.plist"),
        str(Path.home() / "Library/LaunchAgents/com.cloudflared.tunnel.plist.disabled"),
        "/etc/cloudflared/config.yml",
        str(Path.home() / ".cloudflared/config.yml"),
    ]:
        if Path(p).exists():
            configs.append(p)
    return {"processes": procs, "configs_present": configs, "any_running": any(procs.values())}


def collect_listeners() -> list[dict[str, Any]]:
    raw = sh("lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null")
    out = []
    for line in raw.splitlines()[1:]:
        parts = line.split()
        if len(parts) < 9:
            continue
        addr = parts[8]
        open_world = bool(re.match(r"^(\*|0\.0\.0\.0|\[::\]):", addr))
        out.append(
            {
                "command": parts[0],
                "pid": parts[1],
                "user": parts[2],
                "address": addr,
                "all_interfaces": open_world,
            }
        )
    return out


def collect_launch() -> dict[str, Any]:
    interesting = re.compile(
        r"cloudflare|cloudflared|ngrok|tunnel|hubstaff|teamviewer|anydesk|vpn|zoom|docker|redis|ollama|clawdbot|keystone",
        re.I,
    )

    def scan(dirpath: str) -> list[dict[str, Any]]:
        p = Path(dirpath)
        if not p.is_dir():
            return []
        items = []
        for f in sorted(p.iterdir()):
            if not (f.name.endswith(".plist") or ".plist." in f.name or f.name.endswith(".disabled")):
                continue
            if f.name.startswith("com.apple."):
                continue
            items.append({"name": f.name, "flagged": bool(interesting.search(f.name)), "path": str(f)})
        return items

    login_items = []
    raw = sh(
        "osascript -e 'tell application \"System Events\" to get the name of every login item' 2>/dev/null"
    )
    if raw:
        login_items = [x.strip() for x in raw.split(",") if x.strip()]

    return {
        "system_daemons": scan("/Library/LaunchDaemons"),
        "system_agents": scan("/Library/LaunchAgents"),
        "user_agents": scan(str(Path.home() / "Library/LaunchAgents")),
        "login_items": login_items,
    }


def collect_mdm() -> dict[str, Any]:
    profiles = sh("profiles status 2>/dev/null")
    no_profiles = "no configuration profiles" in profiles.lower()
    return {
        "profiles_status": profiles,
        "no_configuration_profiles": no_profiles,
        "managed_preferences_dir": Path("/Library/Managed Preferences").is_dir(),
        "find_my_mac": sh("defaults read /Library/Preferences/com.apple.FindMyMac FMMEnabled 2>/dev/null") == "1",
        "filevault": sh("fdesetup status 2>/dev/null"),
        "sip": sh("csrutil status 2>/dev/null"),
        "enterprise_paths": [
            p
            for p in [
                "/usr/local/bin/jamf",
                "/Library/Application Support/JAMF",
                "/Library/Crowdstrike",
                "/Applications/Falcon.app",
                "/Library/Sentinel",
            ]
            if Path(p).exists()
        ],
    }


def summary_flags(data: dict[str, Any]) -> dict[str, Any]:
    tcc_entries = data["tcc"]["user"].get("entries", []) + data["tcc"]["system"].get("entries", [])
    return {
        "mdm_profiles_present": not data["mdm"].get("no_configuration_profiles", True),
        "monitoring_tcc_grants": sum(1 for e in tcc_entries if e.get("monitoring_hint")),
        "trackers_running": [t["name"] for t in data["trackers"] if t.get("running")],
        "tunnels_running": data["tunnels"].get("any_running", False),
        "open_listeners": sum(1 for L in data["listeners"] if L.get("all_interfaces")),
        "flagged_launch_items": sum(
            1
            for key in ("system_daemons", "system_agents", "user_agents")
            for item in data["launch"].get(key, [])
            if item.get("flagged")
        ),
    }


def main() -> int:
    version = os.environ.get("PK_VERSION", "0.0.0")
    home = Path.home()
    data: dict[str, Any] = {
        "tool": "pk",
        "version": version,
        "schema_version": 2,
        "ts": datetime.now(timezone.utc).isoformat(),
        "platform": {
            "system": sh("uname -s"),
            "machine": sh("uname -m"),
            "macos": sh("sw_vers -productVersion 2>/dev/null") or None,
            "user": os.environ.get("USER"),
            "host": sh("scutil --get ComputerName 2>/dev/null") or sh("hostname"),
        },
        "mdm": collect_mdm(),
        "tcc": {
            "user": collect_tcc(home / "Library/Application Support/com.apple.TCC/TCC.db"),
            "system": collect_tcc(Path("/Library/Application Support/com.apple.TCC/TCC.db")),
        },
        "trackers": collect_trackers(),
        "tunnels": collect_tunnels(),
        "listeners": collect_listeners(),
        "launch": collect_launch(),
    }
    data["summary"] = summary_flags(data)
    json.dump(data, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
