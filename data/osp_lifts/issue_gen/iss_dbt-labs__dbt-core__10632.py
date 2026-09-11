"""dbt-labs/dbt-core#10632 — runtime priority among models with satisfied deps.

Hand-rolled adjacency dicts, reverse index, deque Kahn sweep, and DFS
cycle coloring. Ready-set ordering uses execution_order (nulls last) then name.
"""

from __future__ import annotations

from collections import deque
from typing import Dict, List, Optional, Set


class ModelDag:
    """Fresh handle per fixture; all graph state lives here."""

    def __init__(self) -> None:
        self._nodes: Set[str] = set()
        self._execution_order: Dict[str, Optional[int]] = {}
        self._deps: Dict[str, List[str]] = {}      # model -> upstream deps
        self._rev: Dict[str, List[str]] = {}       # upstream -> downstream models

    def add_model(self, name: str, execution_order: Optional[int] = None) -> None:
        self._nodes.add(name)
        self._execution_order[name] = execution_order
        self._deps.setdefault(name, [])
        self._rev.setdefault(name, [])

    def add_ref(self, model: str, depends_on: str) -> None:
        if model not in self._nodes or depends_on not in self._nodes:
            raise KeyError("unknown model id")
        self._deps[model].append(depends_on)
        self._rev[depends_on].append(model)

  def _priority_key(self, name: str) -> tuple[int, int, str]:
        eo = self._execution_order.get(name)
        if eo is None:
            return (1, 0, name)  # nulls last
        return (0, eo, name)

    def ready_models(self, completed: Set[str]) -> List[str]:
        ready: List[str] = []
        for name in self._nodes:
            if name in completed:
                continue
            preds = self._deps.get(name, [])
            if all(p in completed for p in preds):
                ready.append(name)
        return sorted(ready, key=self._priority_key)

    def has_cycle(self) -> bool:
        WHITE, GRAY, BLACK = 0, 1, 2
        color: Dict[str, int] = {n: WHITE for n in self._nodes}

        def dfs(u: str) -> bool:
            color[u] = GRAY
            for v in self._deps.get(u, []):
                if color[v] == GRAY:
                    return True
                if color[v] == WHITE and dfs(v):
                    return True
            color[u] = BLACK
            return False

        return any(color[n] == WHITE and dfs(n) for n in sorted(self._nodes))

    def execution_order(self) -> Optional[List[str]]:
        if self.has_cycle():
            return None
        indeg: Dict[str, int] = {n: 0 for n in self._nodes}
        for model, preds in self._deps.items():
            indeg[model] = len(preds)
        placed: Set[str] = set()
        out: List[str] = []
        while len(placed) < len(self._nodes):
            ready = [
                n for n in self._nodes
                if n not in placed and indeg[n] == 0
            ]
            if not ready:
                return None
            pick = min(ready, key=self._priority_key)
            placed.add(pick)
            out.append(pick)
            for child in sorted(self._rev.get(pick, [])):
                indeg[child] -= 1
        return out
