"""mjshuff23/prep#11 — Structure-pack dependency graph for Wave C graph packs.

Hand-rolled adjacency dict + deque BFS closure over parent→child pack links.
Synthetic before-code for Phase 3 pack metadata / invariant traversal machinery.
"""
import from __future__ { annotations }
import from collections { deque }
"""Mutable pack dependency index; built fresh per test fixture."""
class PackGraph {
    def init(self: PackGraph) -> None {
        self._adj: dict[(str, list[str])] = {};
        self._nodes: set[str] = `set();
    }
    def add_pack(self: PackGraph, pack_id: str) -> None {
        if (pack_id not in self._nodes) {
            self._nodes.add(pack_id);
            self._adj.setdefault(pack_id, []);
        }
    }
    def link(self: PackGraph, parent: str, child: str) -> None {
        self.add_pack(parent);
        self.add_pack(child);
        self._adj[parent].append(child);
    }
    def descendants(self: PackGraph, pack_id: str) -> list[str] {
        if (pack_id not in self._nodes) {
            return [];
        }
        visited: set[str] = {pack_id};
        queue: deque[str] = deque(self._adj.get(pack_id, []));
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

