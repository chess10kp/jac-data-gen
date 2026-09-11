"""Causal graph, lifted to OSP.

Traces become nodes; cause -> effect links become a typed CausedBy edge
(with weight payload) mirrored by AffectedBy for upstream walks. The
recursive DFS cycle pre-check becomes one reachability flood spawned
from the effect: if it can already reach the cause, the edge would close
a cycle and the facade raises ValueError('causal_cycle'). Claim maps are
the explicit cycle policy -- jac walkers do not dedupe.
Ref: web3guru888/asi-build#280
"""
node Trace {
    has tid: str;
    has phase: str;
}
edge CausedBy {   # cause -> effect
    has weight: float;
}
edge AffectedBy {}  # effect -> cause (mirror)

"""Loader handle: trace ids resolve through this lookup map."""
obj CausalGraph {
    has traces: dict[str, Trace];
    has ids: list[str];

    def resolve(tid: str) -> Trace | None {
        return self.traces.get(tid);
    }
}

def new_graph() -> CausalGraph {
    return CausalGraph(traces={}, ids=[]);
}

def add_trace(graph: CausalGraph, trace_id: str, phase: str) -> None {
    t = Trace(tid=trace_id, phase=phase);
    root ++> t;
    graph.traces[trace_id] = t;
    graph.ids.append(trace_id);
}

walker CycleProbe {
    # Cycle policy: claim-once flood; stops early on hit via disengage
    # (single-probe walk, no sibling frontier to truncate).
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has sink: HitFlag | None = None;

    can probe with Trace entry {
        if here.tid == self.target and self.sink is not None and not (self.sink.hit) {
            self.sink.hit = True;
            disengage;
        }
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        visit [->:CausedBy:->];
    }
}

obj HitFlag {
    has hit: bool = False;
}

"""Link cause -> effect; raises ValueError('causal_cycle') when the edge
would close a cycle."""
def add_cause(graph: CausalGraph, cause_id: str, effect_id: str, weight: float = 1.0) -> None {
    c: Trace = graph.traces[cause_id];
    e: Trace = graph.traces[effect_id];
    if cause_id == effect_id {
        raise ValueError("causal_cycle");
    }
    sink = HitFlag(hit=False);
    e spawn CycleProbe(claimed={}, target=cause_id, sink=sink);
    if sink.hit {
        raise ValueError("causal_cycle");
    }
    c +>:CausedBy(weight=weight):+> e;
    e +>:AffectedBy:+> c;
}

walker EffectFlood {
    has claimed: dict[str, bool] = {};
    has root_id: str = "";
    has found: list[str] = [];

    can step_effect with Trace entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        if here.tid != self.root_id {
            self.found.append(here.tid);
        }
        visit [->:CausedBy:->];
    }
}

walker CauseClimb {
    has claimed: dict[str, bool] = {};
    has root_id: str = "";
    has found: list[str] = [];

    can step_cause with Trace entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        if here.tid != self.root_id {
            self.found.append(here.tid);
        }
        visit [->:AffectedBy:->];
    }
}

"""Transitive downstream effects of ``trace_id`` (exclusive), sorted."""
def effects_of(graph: CausalGraph, trace_id: str) -> list[str] {
    start = graph.resolve(trace_id);
    if start is None {
        return [];
    }
    w = start spawn EffectFlood(claimed={}, root_id=trace_id);
    return sorted(w.found);
}

"""Transitive upstream causes of ``trace_id`` (exclusive), sorted."""
def causes_of(graph: CausalGraph, trace_id: str) -> list[str] {
    start = graph.resolve(trace_id);
    if start is None {
        return [];
    }
    w = start spawn CauseClimb(claimed={}, root_id=trace_id);
    return sorted(w.found);
}

"""(roots, leaves): traces with no causes / no effects. Sorted pair."""
def roots_and_leaves(graph: CausalGraph) -> tuple[list, list] {
    has_cause: dict[str, bool] = {};
    has_effect: dict[str, bool] = {};
    t: Trace;
    for tid in graph.ids {
        t = graph.traces[tid];
        downs = [t->:CausedBy:->];
        if len(downs) > 0 {
            has_effect[tid] = True;
        }
        for d in downs {
            has_cause[d.tid] = True;
        }
    }
    roots: list = [];
    leaves: list = [];
    for tid in graph.ids {
        if tid not in has_cause {
            roots.append(tid);
        }
        if tid not in has_effect {
            leaves.append(tid);
        }
    }
    return (sorted(roots), sorted(leaves));
}
