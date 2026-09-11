"""NousResearch/hermes-agent#81324 — SL3-alpha activation gate dependency routing."""
import from __future__ { annotations }
import from collections { deque }
class GateGraph {
    def init(self: GateGraph) -> None {
        self._gates: set[str] = `set();
        self._depends: dict[(str, list[str])] = {};
        self._status: dict[(str, str)] = {};
    }
}
def load_gate_graph(
    gates: list[str],
    depends_edges: list[tuple[(str, str)]],
    status: (dict[(str, str)] | None) = None
) -> GateGraph {
    g = GateGraph();
    for name in gates {
        g._gates.add(name);
        g._depends.setdefault(name, []);
        g._status[name] = "pending";
    }
    for (blocker, blocked) in depends_edges {
        if ((blocker in g._gates) and (blocked in g._gates)) {
            g._depends.setdefault(blocked, []).append(blocker);
        }
    }
    if status {
        for (k, v) in status.items() {
            if (k in g._gates) {
                g._status[k] = v;
            }
        }
    }
    return g;
}
def ready_gates(store: GateGraph) -> list[str] {
    out: list[str] = [];
    for name in sorted(store._gates) {
        if (store._status.get(name) != "pending") {
            continue;
        }
        blockers = store._depends.get(name, []);
        if all((store._status.get(b) == "passed") for b in blockers) {
            out.append(name);
        }
    }
    return out;
}
def activation_path_depth(store: GateGraph, gate: str) -> int {
    if (gate not in store._gates) {
        return -1;
    }
    depth: dict[(str, int)] = {gate: 0};
    queue: deque[str] = deque([gate]);
    best = 0;
    while queue {
        cur = queue.popleft();
        for dep in store._depends.get(cur, []) {
            nd = depth[cur] + 1;
            if (nd > best) {
                best = nd;
            }
            if ((dep not in depth) or (nd > depth[dep])) {
                depth[dep] = nd;
                queue.append(dep);
            }
        }
    }
    return best;
}
def detect_gate_cycles(store: GateGraph) -> list[tuple[(str, str)]] {
    errors: list[tuple[(str, str)]] = [];
    visited: set[str] = `set();
    stack: set[str] = `set();
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
    for g in sorted(store._gates) {
        if (g not in visited) {
            dfs(g);
        }
    }
    return sorted(errors);
}

