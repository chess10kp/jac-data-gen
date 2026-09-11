"""abdeslam-menacere/ModelTree#39 — Shareable lineage trail subgraph.

Model releases form a derivation graph with predecessor/successor edges.
Trail selection collects ancestors and direct successors around a focal node.
"""

from __future__ import annotations


class LineageBoard:
    def __init__(self) -> None:
        self.parent_of: dict[str, str | None] = {}
        self.children_of: dict[str, list[str]] = {}


def load_lineage(
    nodes: list[str],
    derives: list[tuple[str, str]],
) -> LineageBoard:
    board = LineageBoard()
    for name in nodes:
        board.parent_of[name] = None
        board.children_of.setdefault(name, [])
    for parent, child in derives:
        if parent not in board.parent_of or child not in board.parent_of:
            continue
        board.parent_of[child] = parent
        board.children_of.setdefault(parent, []).append(child)
    return board


def _walk_up(board: LineageBoard, node: str, acc: set[str]) -> None:
    cur = board.parent_of.get(node)
    while cur is not None and cur not in acc:
        acc.add(cur)
        cur = board.parent_of.get(cur)


def trail_nodes(board: LineageBoard, focal: str) -> list[str]:
    if focal not in board.parent_of:
        return []
    acc: set[str] = {focal}
    _walk_up(board, focal, acc)
    for ch in board.children_of.get(focal, []):
        acc.add(ch)
    return sorted(acc)


def sibling_nodes(board: LineageBoard, focal: str) -> list[str]:
    if focal not in board.parent_of:
        return []
    parent = board.parent_of.get(focal)
    if parent is None:
        return []
    sibs = [
        ch
        for ch in board.children_of.get(parent, [])
        if ch != focal
    ]
    return sorted(sibs)
