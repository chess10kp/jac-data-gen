"""imrohitagrawal/narratwin-ai#435 — Governance phase prerequisite graph.

Hand-rolled adjacency dict and stack walk over binding convergence phases;
each phase may require earlier pipeline stages before GREEN authorization.
"""
import from __future__ { annotations }
class PhaseGraph {
    def init(self: PhaseGraph) -> None {
        self.phases: set[str] = `set();
        self.requires: dict[(str, list[str])] = {};
    }
}
def load_phase_graph(
    phases: list[str], requires_edges: list[tuple[(str, str)]]
) -> PhaseGraph {
    g = PhaseGraph();
    for pid in phases {
        g.phases.add(pid);
        g.requires.setdefault(pid, []);
    }
    for (prereq, phase) in requires_edges {
        if ((prereq in g.phases) and (phase in g.phases)) {
            g.requires.setdefault(phase, []).append(prereq);
        }
    }
    return g;
}
def _upstream_ids(g: PhaseGraph, phase_id: str) -> set[str] {
    seen: set[str] = `set();
    stack: list[str] = [phase_id];
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        for req in sorted(g.requires.get(cur, [])) {
            stack.append(req);
        }
    }
    return seen;
}
def upstream_phases(g: PhaseGraph, phase_id: str) -> list[str] {
    if (phase_id not in g.phases) {
        return [];
    }
    return sorted(_upstream_ids(g, phase_id));
}
def ready_phases(g: PhaseGraph, completed: list[str]) -> list[str] {
    done = `set(completed);
    ready: list[str] = [];
    for pid in sorted(g.phases) {
        if (pid in done) {
            continue;
        }
        needs = [
            p
            for p in upstream_phases(g, pid)
            if (p != pid)
        ];
        if all((p in done) for p in needs) {
            ready.append(pid);
        }
    }
    return ready;
}

