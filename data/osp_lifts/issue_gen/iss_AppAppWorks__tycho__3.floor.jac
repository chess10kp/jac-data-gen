"""AppAppWorks/tycho#3 — DAG dominance and ancestor queries for topological constraints.

DSL#2 topological primitives require transitive ancestor checks over a parent
graph. The store keeps parent pointers plus children adjacency and resolves
dominance via recursive ascent with cycle tolerance.
"""
import from __future__ { annotations }
class DagStore {
    def init(self: DagStore) -> None {
        self.parent_of: dict[(str, (str | None))] = {};
        self.children_of: dict[(str, list[str])] = {};
    }
    def add_node(self: DagStore, name: str, parent: (str | None) = None) -> None {
        if ((parent is not None) and (parent not in self.parent_of)) {
            raise KeyError("unknown parent");
        }
        self.parent_of[name] = parent;
        self.children_of.setdefault(name, []);
        if (parent is not None) {
            self.children_of.setdefault(parent, []).append(name);
        }
    }
    def _ancestors(self: DagStore, `node: str) -> list[str] {
        chain: list[str] = [];
        seen: set[str] = {`node};
        cur = self.parent_of.get(`node);
        while (cur is not None) {
            if (cur in seen) {
                break;
            }
            seen.add(cur);
            chain.append(cur);
            cur = self.parent_of.get(cur);
        }
        return chain;
    }
    def dominates(self: DagStore, u: str, v: str) -> bool {
        if ((u not in self.parent_of) or (v not in self.parent_of)) {
            return False;
        }
        if (u == v) {
            return True;
        }
        return (u in self._ancestors(v));
    }
    def ancestors(self: DagStore, `node: str) -> list[str] {
        if (`node not in self.parent_of) {
            raise KeyError("unknown node");
        }
        return sorted(self._ancestors(`node));
    }
}

