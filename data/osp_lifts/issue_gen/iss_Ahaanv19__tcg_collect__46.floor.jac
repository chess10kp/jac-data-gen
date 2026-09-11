"""Ahaanv19/tcg_collect#46 — DS2 objective prerequisite reachability.

Hand-rolled adjacency dict + BFS queue + visited-set closure over prereq links.
link(prereq, obj): completing prereq unlocks obj.
"""
import from __future__ { annotations }
import from collections { deque }
"""Mutable objective prerequisite index; fresh instance per test."""
class ObjectiveGraph {
    def init(self: ObjectiveGraph) -> None {
        self._adj: dict[(str, list[str])] = {};
        self._nodes: set[str] = `set();
    }
    def link(self: ObjectiveGraph, prereq: str, `obj: str) -> None {
        if (prereq not in self._nodes) {
            self._nodes.add(prereq);
            self._adj.setdefault(prereq, []);
        }
        if (`obj not in self._nodes) {
            self._nodes.add(`obj);
            self._adj.setdefault(`obj, []);
        }
        self._adj[prereq].append(`obj);
    }
    def reachable_from(self: ObjectiveGraph, obj_id: str) -> list[str] {
        if (obj_id not in self._nodes) {
            return [];
        }
        visited: set[str] = {obj_id};
        queue: deque[str] = deque(self._adj.get(obj_id, []));
        hits: list[str] = [];
        while queue {
            cur = queue.popleft();
            if (cur in visited) {
                continue;
            }
            visited.add(cur);
            hits.append(cur);
            for nxt in self._adj.get(cur, []) {
                if (nxt not in visited) {
                    queue.append(nxt);
                }
            }
        }
        return sorted(hits);
    }
}

