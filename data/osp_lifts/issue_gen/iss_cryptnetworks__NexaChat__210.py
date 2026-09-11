"""Hand-rolled Cargo-style dependency graph audit helpers.

Issue: cryptnetworks/NexaChat#210
"""

from collections import deque

_ADJ: dict[str, list[str]] = {
    "nexa-desktop": ["tauri"],
    "tauri": ["gtk", "tauri-runtime-wry", "tauri-utils"],
    "gtk": ["glib"],
    "tauri-runtime-wry": ["wry"],
    "wry": ["tao", "webkit2gtk"],
    "webkit2gtk": ["gtk"],
    "tao": ["glib"],
    "tauri-utils": ["urlpattern"],
    "urlpattern": ["unic-ucd-version"],
    "unic-ucd-version": [],
    "glib": [],
}


def direct_dependencies(crate: str) -> list[str]:
    deps = _ADJ.get(crate)
    if deps is None:
        return []
    return sorted(deps)


def transitive_dependencies(root: str) -> list[str]:
    if root not in _ADJ:
        return []
    seen: set[str] = {root}
    queue: deque[str] = deque([root])
    while queue:
        node = queue.popleft()
        for dep in _ADJ.get(node, []):
            if dep not in seen:
                seen.add(dep)
                queue.append(dep)
    seen.discard(root)
    return sorted(seen)


def dependency_paths(root: str, target: str, max_depth: int = 12) -> list[list[str]]:
    if root not in _ADJ or target not in _ADJ:
        return []
    found: list[list[str]] = []
    stack: list[tuple[str, list[str], set[str]]] = [(root, [root], {root})]
    while stack:
        node, trail, on_path = stack.pop()
        if len(trail) > max_depth:
            continue
        if node == target:
            found.append(list(trail))
            continue
        for dep in reversed(sorted(_ADJ.get(node, []))):
            if dep in on_path:
                continue
            next_path = on_path | {dep}
            stack.append((dep, trail + [dep], next_path))
    return sorted(found)


def dedupe_advisory_aliases(records: list[dict]) -> list[dict]:
    groups: dict[tuple[str, ...], dict] = {}
    for rec in records:
        aliases = rec.get("aliases") or [rec["id"]]
        key = tuple(sorted(aliases))
        if key not in groups:
            groups[key] = rec
    return sorted(groups.values(), key=lambda r: r["id"])


def unreviewed_vulnerability_ids(root: str, advisories: list[dict]) -> list[str]:
    reachable = set(transitive_dependencies(root))
    reachable.add(root)
    blocked: list[str] = []
    for adv in dedupe_advisory_aliases(advisories):
        if adv.get("kind") != "vulnerability":
            continue
        if adv["package"] in reachable:
            blocked.append(adv["id"])
    return sorted(blocked)
