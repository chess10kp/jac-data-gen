"""Reference harness for iss_cryptnetworks__NexaChat__210."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_cryptnetworks__NexaChat__210.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
ADVISORIES = [
    {
        "id": "GHSA-wrw7-89jp-8q8g",
        "aliases": ["GHSA-wrw7-89jp-8q8g", "RUSTSEC-2024-0429"],
        "package": "glib",
        "kind": "vulnerability",
    },
    {
        "id": "RUSTSEC-2024-0429",
        "aliases": ["GHSA-wrw7-89jp-8q8g", "RUSTSEC-2024-0429"],
        "package": "glib",
        "kind": "vulnerability",
    },
    {
        "id": "RUSTSEC-gtk-unmaintained",
        "aliases": ["RUSTSEC-gtk-unmaintained"],
        "package": "gtk",
        "kind": "maintenance",
    },
    {
        "id": "RUSTSEC-unic-unmaintained",
        "aliases": ["RUSTSEC-unic-unmaintained"],
        "package": "unic-ucd-version",
        "kind": "maintenance",
    },
]

assert direct_dependencies("tauri") == [
    "gtk",
    "tauri-runtime-wry",
    "tauri-utils",
]
assert direct_dependencies("missing-crate") == []

assert transitive_dependencies("nexa-desktop") == sorted(
    {
        "glib",
        "gtk",
        "tao",
        "tauri",
        "tauri-runtime-wry",
        "tauri-utils",
        "unic-ucd-version",
        "urlpattern",
        "webkit2gtk",
        "wry",
    }
)
assert transitive_dependencies("unknown") == []

assert dependency_paths("nexa-desktop", "glib") == [
    ["nexa-desktop", "tauri", "gtk", "glib"],
    ["nexa-desktop", "tauri", "tauri-runtime-wry", "wry", "tao", "glib"],
    ["nexa-desktop", "tauri", "tauri-runtime-wry", "wry", "webkit2gtk", "gtk", "glib"],
]
assert dependency_paths("nexa-desktop", "glib", max_depth=4) == [
    ["nexa-desktop", "tauri", "gtk", "glib"],
]
assert dependency_paths("nexa-desktop", "missing") == []
assert dependency_paths("missing", "glib") == []

deduped = dedupe_advisory_aliases(ADVISORIES)
assert [r["id"] for r in deduped] == [
    "GHSA-wrw7-89jp-8q8g",
    "RUSTSEC-gtk-unmaintained",
    "RUSTSEC-unic-unmaintained",
]

assert unreviewed_vulnerability_ids("nexa-desktop", ADVISORIES) == [
    "GHSA-wrw7-89jp-8q8g",
]
assert unreviewed_vulnerability_ids("urlpattern", ADVISORIES) == []
assert unreviewed_vulnerability_ids("nexa-desktop", []) == []
print("iss_cryptnetworks__NexaChat__210 ref OK")
