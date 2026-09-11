"""Emrys02/soroban-band#7 — contract dependency cycle detection."""
import from __future__ { annotations }
class ContractGraph {
    def init(self: ContractGraph) -> None {
        self._contracts: set[str] = set();
        self._depends: dict[(str, list[str])] = {};
    }
}
def load_contracts(
    names: list[str], depends_edges: list[tuple[(str, str)]]
) -> ContractGraph {
    g = ContractGraph();
    for name in names {
        g._contracts.add(name);
        g._depends.setdefault(name, []);
    }
    for (blocker, blocked) in depends_edges {
        if ((blocker in g._contracts) and (blocked in g._contracts)) {
            g._depends.setdefault(blocked, []).append(blocker);
            g._depends.setdefault(blocker, g._depends.get(blocker, []));
        }
    }
    return g;
}
def detect_cycles(store: ContractGraph) -> list[tuple[(str, str)]] {
    errors: list[tuple[(str, str)]] = [];
    visited: set[str] = set();
    stack: set[str] = set();
    def dfs(`node: str) -> None {
        visited.add(`node);
        stack.add(`node);
        for dep in store._depends.get(`node, []) {
            if (dep in stack) {
                errors.append((`node, dep));
            } elif (dep not in visited) {
                dfs(dep);
            }
        }
        stack.remove(`node);
    }
    for name in sorted(store._contracts) {
        if (name not in visited) {
            dfs(name);
        }
    }
    return sorted(errors);
}
def cycle_members(store: ContractGraph, start: str) -> (list[str] | None) {
    if (start not in store._contracts) {
        return None;
    }
    visited: set[str] = set();
    stack: list[str] = [];
    def dfs(`node: str) -> (list[str] | None) {
        if (`node in visited) {
            idx = stack.index(`node) if (`node in stack) else -1;
            if (idx >= 0) {
                return stack[idx:];
            }
            return None;
        }
        visited.add(`node);
        stack.append(`node);
        for dep in store._depends.get(`node, []) {
            hit = dfs(dep);
            if (hit is not None) {
                return hit;
            }
        }
        stack.pop();
        return None;
    }
    return dfs(start);
}
def build_order(store: ContractGraph) -> list[str] {
    indeg: dict[(str, int)] = {n: 0 for n in store._contracts};
    for `node in store._contracts {
        for dep in store._depends.get(`node, []) {
            indeg[`node] += 1;
        }
    }
    ready = sorted(
        n
        for (n, d) in indeg.items()
        if (d == 0)
    );
    order: list[str] = [];
    while ready {
        cur = ready.pop(0);
        order.append(cur);
        for other in sorted(store._contracts) {
            if (cur in store._depends.get(other, [])) {
                indeg[other] -= 1;
                if (indeg[other] == 0) {
                    ready.append(other);
                    ready = sorted(ready);
                }
            }
        }
    }
    if (len(order) != len(store._contracts)) {
        return [];
    }
    return order;
}

