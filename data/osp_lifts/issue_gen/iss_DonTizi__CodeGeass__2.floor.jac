"""DonTizi/CodeGeass#2 — task DAG cycle detection and ready frontier."""
import from collections { deque }
class TaskGraph {
    def init(self: TaskGraph) -> None {
        self._tasks: set[str] = set();
        self._deps: dict[(str, list[str])] = {};
        self._done: set[str] = set();
    }
}
def load_tasks(
    tasks: list[str], edges: list[tuple[(str, str)]], done: (list[str] | None) = None
) -> TaskGraph {
    g = TaskGraph();
    for t in tasks {
        g._tasks.add(t);
        g._deps.setdefault(t, []);
    }
    for (blocker, blocked) in edges {
        if ((blocker in g._tasks) and (blocked in g._tasks)) {
            g._deps.setdefault(blocked, []).append(blocker);
        }
    }
    if done {
        g._done = `set(done);
    }
    return g;
}
def has_cycle(store: TaskGraph) -> bool {
    state: dict[(str, int)] = {t: 0 for t in store._tasks};
    for start in sorted(store._tasks) {
        if (state[start] != 0) {
            continue;
        }
        stack = [(start, 0)];
        while stack {
            (`node, idx) = stack[-1];
            if (idx == 0) {
                if (state[`node] == 1) {
                    return True;
                }
                if (state[`node] == 2) {
                    stack.pop();
                    continue;
                }
                state[`node] = 1;
            }
            deps = store._deps.get(`node, []);
            if (idx < len(deps)) {
                stack[-1] = (`node, (idx + 1));
                stack.append((deps[idx], 0));
            } else {
                state[`node] = 2;
                stack.pop();
            }
        }
    }
    return False;
}
def ready_tasks(store: TaskGraph) -> list[str] {
    out: list[str] = [];
    for t in sorted(store._tasks) {
        if (t in store._done) {
            continue;
        }
        blockers = store._deps.get(t, []);
        if all((b in store._done) for b in blockers) {
            out.append(t);
        }
    }
    return out;
}

