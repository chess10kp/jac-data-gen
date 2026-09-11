"""rrousselGit/riverpod#4839 — riverpod_lint sandbox dependency reachability."""
from __future__ import annotations

from dataclasses import dataclass


@dataclass
class Package:
    cid: str
    label: str = ''


_depends: dict[str, list[str]] = {}


def _set_depends(edges: list[tuple[str, str]]) -> None:
    global _depends
    adj: dict[str, list[str]] = {}
    for left, right in edges:
        if left not in adj:
            adj[left] = []
        adj[left].append(right)
    _depends = adj


def _index_packages(nodes: list[Package]) -> dict[str, Package]:
    idx: dict[str, Package] = {}
    for nd in nodes:
        idx[nd.cid] = nd
    return idx


def _traverse(start: str, claimed: dict[str, bool], on_node) -> None:
    queue: list[str] = [start]
    while queue:
        cid = queue.pop(0)
        if cid in claimed:
            continue
        claimed[cid] = True
        on_node(cid)
        for dep in _depends.get(cid, []):
            queue.insert(0, dep)


def make_sandbox_graph() -> list[Package]:
    lint = Package(cid='riverpod_lint', label='3.1.8')
    utils = Package(cid='riverpod_analyzer_utils', label='1.0.0-dev.11')
    plugin = Package(cid='analysis_server_plugin', label='0.3.18')
    analyzer = Package(cid='analyzer', label='13.3.0')
    _set_depends([
        ('riverpod_lint', 'riverpod_analyzer_utils'),
        ('riverpod_analyzer_utils', 'analysis_server_plugin'),
        ('riverpod_analyzer_utils', 'analyzer'),
        ('analysis_server_plugin', 'analyzer'),
        ('analyzer', 'riverpod_lint'),
    ])
    return [lint, utils, plugin, analyzer]


def make_diamond_graph() -> list[Package]:
    lint = Package(cid='riverpod_lint')
    utils = Package(cid='riverpod_analyzer_utils')
    analyzer = Package(cid='analyzer')
    plugin = Package(cid='analysis_server_plugin')
    _set_depends([
        ('riverpod_lint', 'riverpod_analyzer_utils'),
        ('riverpod_lint', 'analyzer'),
        ('riverpod_analyzer_utils', 'analysis_server_plugin'),
        ('analyzer', 'analysis_server_plugin'),
    ])
    return [lint, utils, analyzer, plugin]


def reachable_sorted(start: str, nodes: list[Package]) -> list[str]:
    idx = _index_packages(nodes)
    if start not in idx:
        return []
    found: list[str] = []
    claimed: dict[str, bool] = {}

    def on_node(cid: str) -> None:
        print('reach ', cid)
        if cid != start:
            found.append(cid)

    _traverse(start, claimed, on_node)
    return sorted(found)


def has_path(start: str, end: str, nodes: list[Package]) -> bool:
    idx = _index_packages(nodes)
    if start not in idx:
        return False
    if end not in idx:
        return False
    hit = False
    claimed: dict[str, bool] = {}

    def on_node(cid: str) -> None:
        nonlocal hit
        print('reach ', cid)
        if cid == end:
            hit = True

    _traverse(start, claimed, on_node)
    return hit


def sdk_handshake_hangs(sdk: str, lint_version: str) -> bool:
    if lint_version == '3.1.4':
        return False
    if lint_version == '3.1.8' and sdk == '3.12.2':
        return True
    return False
