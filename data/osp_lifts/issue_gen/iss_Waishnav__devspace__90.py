"""Waishnav/devspace#90 — open_workspace eagerly walks nested agent instruction files.

Models findAvailableAgentsFiles()/walkWorkspace(): parent/child maps plus deque BFS
with a visited set to collect every directory bearing AGENTS.md or CLAUDE.md.
"""

from __future__ import annotations

from collections import deque


class WorkspaceStore:
    def __init__(self) -> None:
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._has_agent: dict[str, bool] = {}
        self._nodes: set[str] = set()


def load_tree(specs: list[tuple[str, str | None, bool]]) -> WorkspaceStore:
    # (dir_path, parent_path, has_agent_md)
    g = WorkspaceStore()
    for path, _par, has_md in specs:
        g._nodes.add(path)
        g._parent.setdefault(path, None)
        g._children.setdefault(path, [])
        g._has_agent[path] = has_md
    for path, par, has_md in specs:
        g._has_agent[path] = has_md
        if par is not None and par in g._nodes:
            old = g._parent.get(path)
            if old is not None and old != par:
                g._children[old] = [c for c in g._children[old] if c != path]
            g._parent[path] = par
            if path not in g._children[par]:
                g._children[par].append(path)
    return g


def discover_agent_files(g: WorkspaceStore, root_path: str) -> list[str]:
    if root_path not in g._nodes:
        return []
    hits: list[str] = []
    claimed: set[str] = set()
    queue: deque[str] = deque([root_path])
    while queue:
        cur = queue.popleft()
        if cur in claimed:
            continue
        claimed.add(cur)
        if g._has_agent.get(cur, False):
            hits.append(cur)
        for ch in g._children.get(cur, []):
            if ch not in claimed:
                queue.append(ch)
    return sorted(hits)
