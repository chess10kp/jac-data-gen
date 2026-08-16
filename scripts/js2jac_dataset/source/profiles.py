#!/usr/bin/env python3
"""Stack profiles for js2jac sourcing: define the convertible envelope ONCE.

A profile is a dependency-shape gate applied at clone time (harvest.py,
wall_probe.mjs) plus optional GitHub search qualifiers applied at discovery
(discover.py). All three stages read the SAME profiles.json so "the stack we
target" lives in one place. `react` reproduces the historical React-only gate
and is the default, so existing runs are unchanged.

Matching semantics (mirrored in wall_probe.mjs -- keep in sync):
  deny_any        reject if ANY dep matches a pattern (CSS-in-JS, RTK, ...)
  require_groups  every group must have >=1 matching dep (AND of ORs)
  prefer_any      soft signal -> reasons, for future ranking (not a gate)
Patterns ending in `*` are prefix matches (e.g. `@radix-ui/*`).
"""
from __future__ import annotations

import json
from pathlib import Path

PROFILES_PATH = Path(__file__).with_name("profiles.json")


def load_profiles() -> dict:
    return json.loads(PROFILES_PATH.read_text())


def get_profile(name: str) -> dict:
    profs = load_profiles()
    if name not in profs:
        raise SystemExit(
            f"unknown profile {name!r}; have: {', '.join(sorted(profs))}"
        )
    return profs[name]


def _dep_match(dep: str, pattern: str) -> bool:
    if pattern.endswith("*"):
        return dep.startswith(pattern[:-1])
    return dep == pattern


def match_deps(deps, profile: dict) -> tuple[bool, list[str]]:
    """Return (accepted, reasons). `deps` is an iterable of package names."""
    deps = set(deps)
    for pat in profile.get("deny_any", []):
        hit = next((d for d in deps if _dep_match(d, pat)), None)
        if hit:
            return False, [f"deny:{hit}"]
    for group in profile.get("require_groups", []):
        if not any(_dep_match(d, pat) for d in deps for pat in group):
            return False, [f"missing:{'|'.join(group)}"]
    reasons = []
    for pat in profile.get("prefer_any", []):
        hit = next((d for d in deps if _dep_match(d, pat)), None)
        if hit:
            reasons.append(f"prefer:{hit}")
    return True, reasons


def path_excluded(relpath: str, profile: dict) -> bool:
    """True if `relpath` matches a profile path_exclude glob (substring match).

    Used to drop vendored boilerplate (e.g. shadcn `components/ui/*`) that is
    near-identical across repos and, for shadcn, already ships natively in Jac's
    registry -- converting it is duplicate, low-value training signal.
    """
    rp = relpath.replace("\\", "/")
    return any(pat in rp for pat in profile.get("path_exclude", []))


def read_deps(package_json: Path) -> set[str]:
    """All dependency names (prod + dev) from a package.json, or empty set."""
    try:
        data = json.loads(package_json.read_text())
    except Exception:
        return set()
    return {
        *data.get("dependencies", {}),
        *data.get("devDependencies", {}),
    }
