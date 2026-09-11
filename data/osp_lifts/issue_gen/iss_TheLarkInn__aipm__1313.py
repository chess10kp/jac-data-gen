"""TheLarkInn/aipm#1313 — transitive build lineage with forked feature-set paths."""

from collections import deque
from typing import Any

ROOT = "aipm"


def _fresh_lineage() -> dict[str, Any]:
    adj: dict[str, list[str]] = {
        "aipm": ["jsonschema", "libgit2-sys", "syn"],
        "jsonschema": ["reqwest"],
        "reqwest": ["rustls-ring", "rustls-aws"],
        "rustls-ring": [],
        "rustls-aws": ["aws-lc-sys"],
        "libgit2-sys": [],
        "syn": [],
        "aws-lc-sys": [],
    }
    features: dict[str, set[str]] = {
        "rustls-ring": {"ring", "tls12"},
        "rustls-aws": {"aws-lc-rs", "tls12"},
        "jsonschema": {"reqwest", "resolve-http", "tls-aws-lc-rs"},
    }
    weights: dict[str, float] = {
        "aipm": 1.0,
        "jsonschema": 22.6,
        "reqwest": 5.0,
        "rustls-ring": 22.7,
        "rustls-aws": 22.1,
        "aws-lc-sys": 83.9,
        "libgit2-sys": 70.0,
        "syn": 27.4,
    }
    for node in adj:
        adj[node] = sorted(adj[node])
    return {"adj": adj, "features": features, "weights": weights}


def lineage_nodes(root: str, graph: dict[str, Any] | None = None) -> list[str]:
    g = graph if graph is not None else _fresh_lineage()
    if root not in g["adj"]:
        raise KeyError(root)
    seen: set[str] = set()
    queue: deque[str] = deque([root])
    while queue:
        node = queue.popleft()
        if node in seen:
            continue
        seen.add(node)
        for nxt in g["adj"][node]:
            queue.append(nxt)
    return sorted(seen)


def fork_paths(root: str, graph: dict[str, Any] | None = None) -> list[list[str]]:
    g = graph if graph is not None else _fresh_lineage()
    nodes = set(lineage_nodes(root, g))
    paths: list[list[str]] = []

    def dfs(node: str, trail: list[str]) -> None:
        trail.append(node)
        outs = [n for n in g["adj"][node] if n in nodes]
        if not outs:
            paths.append(list(trail))
        else:
            for nxt in outs:
                dfs(nxt, trail)
        trail.pop()

    dfs(root, [])
    return sorted(paths)


def feature_lineage(unit: str, graph: dict[str, Any] | None = None) -> list[str]:
    g = graph if graph is not None else _fresh_lineage()
    if unit not in g["adj"]:
        raise KeyError(unit)
    feats = g["features"].get(unit, set())
    queue: deque[str] = deque(sorted(feats))
    seen: set[str] = set()
    while queue:
        item = queue.popleft()
        if item in seen:
            continue
        seen.add(item)
        for nxt in sorted(g["features"].get(item, set())):
            queue.append(nxt)
    return sorted(seen)


def heaviest_fork(root: str, graph: dict[str, Any] | None = None) -> list[str]:
    g = graph if graph is not None else _fresh_lineage()
    best: list[str] = []
    best_w = -1.0
    for path in fork_paths(root, g):
        w = sum(g["weights"][n] for n in path)
        if w > best_w or (w == best_w and path < best):
            best = path
            best_w = w
    return best


def duplicate_lineage_crates(records: list[tuple[str, str]]) -> dict[str, list[str]]:
    acc: dict[str, set[str]] = {}
    for crate, version in records:
        acc.setdefault(crate, set()).add(version)
    return {k: sorted(v) for k, v in sorted(acc.items()) if len(v) > 1}
