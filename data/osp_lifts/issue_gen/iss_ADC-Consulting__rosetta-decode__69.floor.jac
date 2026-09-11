"""ADC-Consulting/rosetta-decode#69 — data lineage DAG for cloud workflow tasks."""
import from collections { deque }
class Pipeline {
    def init(self: Pipeline) -> None {
        self._tasks: set[str] = `set();
        self._upstream: dict[(str, list[str])] = {};
    }
}
def load_pipeline(tasks: list[str], edges: list[tuple[(str, str)]]) -> Pipeline {
    p = Pipeline();
    for t in tasks {
        p._tasks.add(t);
        p._upstream.setdefault(t, []);
    }
    for (up, down) in edges {
        if ((up in p._tasks) and (down in p._tasks)) {
            p._upstream.setdefault(down, []).append(up);
            p._upstream.setdefault(up, p._upstream.get(up, []));
        }
    }
    return p;
}
def upstream_tasks(store: Pipeline, task: str) -> list[str] {
    if (task not in store._tasks) {
        return [];
    }
    seen: set[str] = {task};
    queue: deque[str] = deque([task]);
    out: set[str] = `set();
    while queue {
        cur = queue.popleft();
        for u in store._upstream.get(cur, []) {
            out.add(u);
            if (u not in seen) {
                seen.add(u);
                queue.append(u);
            }
        }
    }
    return sorted(out);
}
def lineage_depth(store: Pipeline, task: str) -> int {
    if (task not in store._tasks) {
        return -1;
    }
    depth: dict[(str, int)] = {task: 0};
    queue: deque[str] = deque([task]);
    best = 0;
    while queue {
        cur = queue.popleft();
        for u in store._upstream.get(cur, []) {
            nd = depth[cur] + 1;
            if (nd > best) {
                best = nd;
            }
            if ((u not in depth) or (nd > depth[u])) {
                depth[u] = nd;
                queue.append(u);
            }
        }
    }
    return best;
}

