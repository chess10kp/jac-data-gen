"""WordPress/gutenberg#80682 — @wordpress/scripts vulnerable build-tool dependency audit.

Hand-rolled adjacency dict + deque BFS for npm install-tree reachability,
stack-based audit-path enumeration, and declared-range drift checks against
the published changelog before patching transitive advisories.
"""

from __future__ import annotations

from collections import deque


class PackageGraph:
    def __init__(self) -> None:
        self.resolved: dict[str, str] = {}
        self.deps: dict[str, list[str]] = {}
        self.root_declared: dict[str, str] = {}


def load_package_graph(
    packages: list[tuple[str, str]],
    edges: list[tuple[str, str]],
    *,
    root_declared: dict[str, str] | None = None,
) -> PackageGraph:
    g = PackageGraph()
    for name, version in packages:
        g.resolved[name] = version
        g.deps.setdefault(name, [])
    for src, dst in edges:
        if src in g.deps and dst in g.resolved:
            g.deps[src].append(dst)
    if root_declared:
        g.root_declared = dict(root_declared)
    return g


def direct_dependencies(g: PackageGraph, pkg: str) -> list[str]:
    if pkg not in g.resolved:
        return []
    return sorted(g.deps.get(pkg, []))


def transitive_dependencies(g: PackageGraph, root: str) -> list[str]:
    if root not in g.resolved:
        return []
    seen: set[str] = {root}
    queue: deque[str] = deque(g.deps.get(root, []))
    found: set[str] = set()
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        found.add(cur)
        queue.extend(g.deps.get(cur, []))
    return sorted(found)


def dependency_paths(
    g: PackageGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]]:
    if source not in g.resolved or target not in g.resolved:
        return []
    out: list[list[str]] = []
    stack: list[tuple[str, list[str]]] = [(source, [source])]
    while stack:
        node, trail = stack.pop()
        if node == target:
            out.append(trail)
            continue
        if len(trail) >= max_depth:
            continue
        for nxt in g.deps.get(node, []):
            if nxt not in trail:
                stack.append((nxt, trail + [nxt]))
    return sorted(out)


def dedupe_advisory_aliases(records: list[dict]) -> list[dict]:
    groups: dict[tuple[str, ...], dict] = {}
    for rec in records:
        aliases = rec.get("aliases") or [rec["id"]]
        key = tuple(sorted(aliases))
        if key not in groups:
            groups[key] = rec
    return sorted(groups.values(), key=lambda r: r["id"])


def reachable_vulnerability_ids(
    g: PackageGraph,
    root: str,
    advisories: list[dict],
) -> list[str]:
    reachable = set(transitive_dependencies(g, root))
    reachable.add(root)
    blocked: list[str] = []
    for adv in dedupe_advisory_aliases(advisories):
        if adv.get("kind") != "vulnerability":
            continue
        if adv["package"] in reachable:
            blocked.append(adv["id"])
    return sorted(blocked)


def changelog_declared_drift(
    g: PackageGraph,
    root: str,
    changelog_declared: dict[str, str],
) -> list[str]:
    if root not in g.resolved:
        return []
    drifted: list[str] = []
    for dep in sorted(g.deps.get(root, [])):
        actual = g.root_declared.get(dep, "")
        expected = changelog_declared.get(dep, "")
        if expected and actual != expected:
            drifted.append(dep)
    return drifted
