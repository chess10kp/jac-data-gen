"""Harborline-Software/shipyard#3090 — subtree aggregation over containment tree."""
import from __future__ { annotations }
import from collections { deque }
import from typing { Dict, List, Optional, Set, Tuple }
class HullTree {
    def init(self: HullTree) -> None {
        self._labels: Dict[(str, str)] = {};
        self._weights: Dict[(str, int)] = {};
        self._children: Dict[(str, List[str])] = {};
        self._parent: Dict[(str, Optional[str])] = {};
    }
    def add_part(
        self: HullTree,
        part_id: str,
        label: str = "",
        weight: int = 0,
        parent_id: Optional[str] = None
    ) -> None {
        if (part_id in self._labels) {
            return;
        }
        if ((parent_id is not None) and (parent_id not in self._labels)) {
            raise KeyError("unknown parent");
        }
        self._labels[part_id] = label;
        self._weights[part_id] = weight;
        self._children.setdefault(part_id, []);
        self._parent[part_id] = parent_id;
        if (parent_id is not None) {
            self._children.setdefault(parent_id, []).append(part_id);
        }
    }
    def aggregate_subtree(self: HullTree, root_id: str) -> Tuple[(int, int)] {
        if (root_id not in self._labels) {
            return (0, 0);
        }
        seen: Set[str] = `set();
        stack: List[str] = [root_id];
        (total, count) = (0, 0);
        while stack {
            cur = stack.pop();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            total += self._weights[cur];
            count += 1;
            for ch in self._children.get(cur, []) {
                if (ch not in seen) {
                    stack.append(ch);
                }
            }
        }
        return (total, count);
    }
    def descendants(self: HullTree, root_id: str) -> List[str] {
        if (root_id not in self._labels) {
            return [];
        }
        seen: Set[str] = `set();
        q: deque[str] = deque([root_id]);
        out: List[str] = [];
        while q {
            cur = q.popleft();
            if (cur in seen) {
                continue;
            }
            seen.add(cur);
            out.append(cur);
            for ch in self._children.get(cur, []) {
                if (ch not in seen) {
                    q.append(ch);
                }
            }
        }
        return out;
    }
    def ancestors(self: HullTree, part_id: str) -> List[str] {
        if (part_id not in self._labels) {
            return [];
        }
        out: List[str] = [];
        cur: Optional[str] = self._parent.get(part_id);
        while (cur is not None) {
            out.append(cur);
            cur = self._parent.get(cur);
        }
        return out;
    }
}
def build_hull() -> HullTree {
    return HullTree();
}

