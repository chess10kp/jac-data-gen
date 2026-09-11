"""DotNaos/project-space#879 — Recursive change decomposition tree accounting.

Hand-rolled parent/child pointers for zero-trust reconstruction review states
and lossless leaf flattening before stacked delivery workflow lands.
"""

from __future__ import annotations

from collections import deque


class ChangeTree:
    def __init__(self) -> None:
        self._pieces: set[str] = set()
        self._parent: dict[str, str | None] = {}
        self._children: dict[str, list[str]] = {}
        self._state: dict[str, str] = {}


def load_change_tree(
    pieces: list[str],
    parent_edges: list[tuple[str, str]],
    states: list[tuple[str, str]],
) -> ChangeTree:
    tree = ChangeTree()
    for pid in pieces:
        tree._pieces.add(pid)
        tree._parent[pid] = None
        tree._children.setdefault(pid, [])
        tree._state[pid] = "deferred"
    for parent, child in parent_edges:
        if parent in tree._pieces and child in tree._pieces:
            tree._parent[child] = parent
            tree._children.setdefault(parent, []).append(child)
    for pid, state in states:
        if pid in tree._pieces:
            tree._state[pid] = state
    return tree


def descendant_pieces(tree: ChangeTree, root: str) -> list[str]:
    if root not in tree._pieces:
        return []
    seen: set[str] = set()
    q: deque[str] = deque(tree._children.get(root, []))
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for ch in tree._children.get(cur, []):
            if ch not in seen:
                q.append(ch)
    return sorted(seen)


def flatten_leaves(tree: ChangeTree, root: str) -> list[str]:
    if root not in tree._pieces:
        return []
    leaves: list[str] = []

    def walk(node: str) -> None:
        kids = tree._children.get(node, [])
        if not kids:
            leaves.append(node)
            return
        for ch in sorted(kids):
            walk(ch)

    walk(root)
    return leaves


def partition_accounting(tree: ChangeTree) -> dict[str, int]:
    counts = {"accepted": 0, "rejected": 0, "deferred": 0}
    for pid in tree._pieces:
        st = tree._state.get(pid, "deferred")
        if st in counts:
            counts[st] += 1
    return counts


def review_complete(tree: ChangeTree) -> bool:
    return partition_accounting(tree)["deferred"] == 0
