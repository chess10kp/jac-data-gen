"""views-platform/views-pipeline-core#141 — Pipeline stage prerequisite scheduling.

Hand-rolled parent pointers and child adjacency for numpy pipeline stage
readiness after FeatureFrame integration prerequisites complete.
"""
import from __future__ { annotations }
class PipelineGraph {
    def init(self: PipelineGraph) -> None {
        self.stages: set[str] = `set();
        self.blocked_by: dict[(str, list[str])] = {};
    }
}
def load_pipeline(
    stages: list[str], requires: list[tuple[(str, str)]]
) -> PipelineGraph {
    g = PipelineGraph();
    for sid in stages {
        g.stages.add(sid);
        g.blocked_by.setdefault(sid, []);
    }
    for (prereq, stage) in requires {
        if ((prereq in g.stages) and (stage in g.stages)) {
            g.blocked_by.setdefault(stage, []).append(prereq);
        }
    }
    return g;
}
def _upstream_ids(g: PipelineGraph, sid: str) -> set[str] {
    seen: set[str] = `set();
    stack: list[str] = [sid];
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        for req in sorted(g.blocked_by.get(cur, [])) {
            stack.append(req);
        }
    }
    return seen;
}
def all_prerequisites(g: PipelineGraph, stage: str) -> list[str] {
    if (stage not in g.stages) {
        return [];
    }
    return sorted(_upstream_ids(g, stage));
}
def runnable_stages(g: PipelineGraph, completed: list[str]) -> list[str] {
    done = `set(completed);
    ready: list[str] = [];
    for sid in sorted(g.stages) {
        if (sid in done) {
            continue;
        }
        needs = [
            p
            for p in all_prerequisites(g, sid)
            if (p != sid)
        ];
        if all((p in done) for p in needs) {
            ready.append(sid);
        }
    }
    return ready;
}

