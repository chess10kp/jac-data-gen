"""aetorresdev/ai-minions#341 — Execution graph cycle validation."""

from __future__ import annotations


class ExecGraph:
    def __init__(self) -> None:
        self._nodes: set[str] = set()
        self._edges: dict[str, list[str]] = {}


def load_exec_graph(
    nodes: list[str],
    edges: list[tuple[str, str]],
) -> ExecGraph:
    g = ExecGraph()
    for n in nodes:
        g._nodes.add(n)
        g._edges.setdefault(n, [])
    for src, dst in edges:
        if src in g._nodes and dst in g._nodes:
            g._edges[src].append(dst)
    return g


def detect_exec_cycles(g: ExecGraph) -> list[str]:
    gray: set[str] = set()
    black: set[str] = set()
    cycles: list[str] = []

    def dfs(node: str, stack: list[str]) -> None:
        if node in black:
            return
        if node in gray:
            cycles.append("cycle: " + " -> ".join(stack + [node]))
            return
        gray.add(node)
        stack.append(node)
        for nxt in g._edges.get(node, []):
            dfs(nxt, stack)
        stack.pop()
        gray.remove(node)
        black.add(node)

    for n in sorted(g._nodes):
        if n not in black:
            dfs(n, [])
    return cycles


def valid_exec_graph(g: ExecGraph) -> bool:
    return len(detect_exec_cycles(g)) == 0
