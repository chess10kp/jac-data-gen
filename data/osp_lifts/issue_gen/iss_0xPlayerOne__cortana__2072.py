"""0xPlayerOne/cortana#2072 — Bounded code relationship neighborhood."""

from __future__ import annotations

from collections import deque


class CodeGraph:
    def __init__(self) -> None:
        self._symbols: set[str] = set()
        self._refs: dict[str, list[str]] = {}


def load_code_graph(
    symbols: list[str],
    refs: list[tuple[str, str]],
) -> CodeGraph:
    g = CodeGraph()
    for sid in symbols:
        g._symbols.add(sid)
        g._refs.setdefault(sid, [])
    for src, dst in refs:
        if src in g._symbols and dst in g._symbols:
            g._refs.setdefault(src, []).append(dst)
    return g


def neighborhood(
    graph: CodeGraph,
    seed: str,
    max_depth: int,
) -> list[str]:
    if seed not in graph._symbols or max_depth < 0:
        return []
    seen: set[str] = set()
    queue: deque[tuple[str, int]] = deque([(seed, 0)])
    while queue:
        cur, depth = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        if depth >= max_depth:
            continue
        for nxt in graph._refs.get(cur, []):
            if nxt not in seen:
                queue.append((nxt, depth + 1))
    return sorted(seen)
