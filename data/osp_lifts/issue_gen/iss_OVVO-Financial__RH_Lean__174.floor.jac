"""OVVO-Financial/RH_Lean#174 — Theorem dependency chain for RH formalization route."""
import from __future__ { annotations }
class TheoremGraph {
    def init(self: TheoremGraph) -> None {
        self._parent_of: dict[(str, (str | None))] = {};
        self._children_of: dict[(str, list[str])] = {};
    }
}
def load_theorems(stmts: list[tuple[(str, (str | None))]]) -> TheoremGraph {
    g = TheoremGraph();
    for (name, parent) in stmts {
        if ((parent is not None) and (parent not in g._parent_of)) {
            raise KeyError("unknown prerequisite");
        }
        g._parent_of[name] = parent;
        g._children_of.setdefault(name, []);
        if (parent is not None) {
            g._children_of.setdefault(parent, []).append(name);
        }
    }
    return g;
}
def proof_chain(store: TheoremGraph, target: str) -> list[str] {
    if (target not in store._parent_of) {
        return [];
    }
    chain: list[str] = [];
    cur: (str | None) = target;
    seen: set[str] = `set();
    while (cur is not None) {
        if (cur in seen) {
            break;
        }
        seen.add(cur);
        chain.append(cur);
        cur = store._parent_of.get(cur);
    }
    rev = `list(reversed(chain));
    return rev;
}
def downstream_theorems(store: TheoremGraph, `root: str) -> list[str] {
    if (`root not in store._parent_of) {
        return [];
    }
    stack = [`root];
    seen: set[str] = `set();
    out: list[str] = [];
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        out.append(cur);
        for ch in store._children_of.get(cur, []) {
            stack.append(ch);
        }
    }
    return sorted(out);
}

