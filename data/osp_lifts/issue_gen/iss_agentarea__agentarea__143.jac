"""agentarea/agentarea#143 — Async agent delegation with cascading pause/resume/cancel."""

obj AgentRuntime { has nodes: dict[str, Agent] = {}; }
node Agent { has name: str; has state: str = "running"; }
edge Delegates {}
edge References {}

walker DelegatedSubtree {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Agent entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.hits.append(here.name);
        visit [->:Delegates:->][?:Agent] else { disengage; };
    }
}

def build_runtime(
    agents: list[str],
    delegates: list[tuple[str, str]],
    refs: list[tuple[str, str]] | None = None,
) -> AgentRuntime {
    rt = AgentRuntime();
    for name in agents {
        if name not in rt.nodes {
            ag = Agent(name=name);
            root ++> ag;
            rt.nodes[name] = ag;
        }
    }
    for (mgr, sub) in delegates {
        par = rt.nodes.get(mgr, None);
        sub_nd = rt.nodes.get(sub, None);
        if par is not None and sub_nd is not None {
            par +>:Delegates:+> sub_nd;
        }
    }
    for (src, dst) in refs or [] {
        s = rt.nodes.get(src, None);
        t = rt.nodes.get(dst, None);
        if s is not None and t is not None { s +>:References:+> t; }
    }
    return rt;
}

def _ancestors_running(rt: AgentRuntime, agent: Agent) -> bool {
    cur = agent;
    seen: dict[str, bool] = {};
    while True {
        parents = [cur <-:Delegates:<-][?:Agent];
        if not parents { break; }
        par = parents[0];
        if par.name in seen { break; }
        seen[par.name] = True;
        if par.state != "running" { return False; }
        cur = par;
    }
    return True;
}

def delegated_subtree(rt: AgentRuntime, manager: str) -> list[str] {
    start = rt.nodes.get(manager, None);
    if start is None { return []; }
    w = start spawn DelegatedSubtree();
    return sorted(w.hits);
}

def cascade_pause(rt: AgentRuntime, agent: str) -> list[str] {
    start = rt.nodes.get(agent, None);
    if start is None { return []; }
    w = start spawn DelegatedSubtree();
    changed: list[str] = [];
    for nm in w.hits {
        ag = rt.nodes[nm];
        if ag.state == "running" {
            ag.state = "paused";
            changed.append(nm);
        }
    }
    return sorted(changed);
}

def cascade_resume(rt: AgentRuntime, agent: str) -> list[str] {
    start = rt.nodes.get(agent, None);
    if start is None { return []; }
    w = start spawn DelegatedSubtree();
    changed: list[str] = [];
    for nm in w.hits {
        ag = rt.nodes[nm];
        if ag.state != "paused" { continue; }
        if not _ancestors_running(rt, ag) { continue; }
        ag.state = "running";
        changed.append(nm);
    }
    return sorted(changed);
}

def cascade_cancel(rt: AgentRuntime, agent: str) -> list[str] {
    start = rt.nodes.get(agent, None);
    if start is None { return []; }
    w = start spawn DelegatedSubtree();
    changed: list[str] = [];
    for nm in w.hits {
        ag = rt.nodes[nm];
        if ag.state != "cancelled" {
            ag.state = "cancelled";
            changed.append(nm);
        }
    }
    return sorted(changed);
}

def agent_state(rt: AgentRuntime, agent: str) -> str | None {
    ag = rt.nodes.get(agent, None);
    if ag is None { return None; }
    return ag.state;
}

def ref_violations(rt: AgentRuntime, manager: str) -> list[str] {
    start = rt.nodes.get(manager, None);
    if start is None { return []; }
    w = start spawn DelegatedSubtree();
    scope: dict[str, bool] = {};
    for nm in w.hits { scope[nm] = True; }
    violations: list[str] = [];
    for nm in w.hits {
        ag = rt.nodes[nm];
        for tgt in [ag ->:References:->][?:Agent] {
            if tgt.name not in scope {
                violations.append(f"{nm}->{tgt.name}");
            }
        }
    }
    return sorted(violations);
}
