"""LAA-Software-Engineering/agentic-control-plane#194 — Subworkflow invocation graph."""
import from __future__ { annotations }
import from collections { deque }
class WorkflowStore {
    def init(self: WorkflowStore) -> None {
        self._workflows: set[str] = `set();
        self._invokes: dict[(str, list[str])] = {};
    }
}
def load_workflows(
    names: list[str], invokes_edges: list[tuple[(str, str)]]
) -> WorkflowStore {
    ws = WorkflowStore();
    for name in names {
        ws._workflows.add(name);
        ws._invokes.setdefault(name, []);
    }
    for (caller, callee) in invokes_edges {
        if ((caller in ws._workflows) and (callee in ws._workflows)) {
            ws._invokes.setdefault(caller, []).append(callee);
            ws._invokes.setdefault(callee, ws._invokes.get(callee, []));
        }
    }
    return ws;
}
def _collect_reachable(store: WorkflowStore, `root: str, acc: set[str]) -> None {
    for nxt in store._invokes.get(`root, []) {
        if (nxt in acc) {
            continue;
        }
        acc.add(nxt);
        _collect_reachable(store, nxt, acc);
    }
}
def reachable_subworkflows(store: WorkflowStore, workflow: str) -> list[str] {
    if (workflow not in store._workflows) {
        return [];
    }
    seen: set[str] = {workflow};
    work: deque[str] = deque([workflow]);
    while work {
        cur = work.popleft();
        for nxt in store._invokes.get(cur, []) {
            if (nxt not in seen) {
                seen.add(nxt);
                work.append(nxt);
            }
        }
    }
    closure: set[str] = `set(seen);
    _collect_reachable(store, workflow, closure);
    return sorted(closure);
}
def validate_no_recursion(store: WorkflowStore) -> list[tuple[(str, str)]] {
    errors: list[tuple[(str, str)]] = [];
    visited: set[str] = `set();
    stack: set[str] = `set();
    def dfs(`node: str) -> None {
        visited.add(`node);
        stack.add(`node);
        for nxt in store._invokes.get(`node, []) {
            if (nxt in stack) {
                errors.append((`node, nxt));
            } elif (nxt not in visited) {
                dfs(nxt);
            }
        }
        stack.remove(`node);
    }
    for wf in sorted(store._workflows) {
        if (wf not in visited) {
            dfs(wf);
        }
    }
    return sorted(errors);
}
def max_invoke_depth(store: WorkflowStore, workflow: str, limit: int) -> bool {
    if (workflow not in store._workflows) {
        return False;
    }
    depth: dict[(str, int)] = {workflow: 0};
    queue: deque[str] = deque([workflow]);
    while queue {
        cur = queue.popleft();
        for nxt in store._invokes.get(cur, []) {
            nd = depth[cur] + 1;
            if (nd > limit) {
                return False;
            }
            if ((nxt not in depth) or (nd > depth[nxt])) {
                depth[nxt] = nd;
                queue.append(nxt);
            }
        }
    }
    return True;
}

