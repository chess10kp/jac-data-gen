"""Deen-Bridge/dnb-ai#155 — Intelligent agent task decomposition dependency planner."""

node DecompTask {
    has tid: str;
}

edge PrereqOf: DecompTask --> DecompTask {}

obj DecompStore {
    has tasks: set[str] = set();
    has prereqs: dict[str, list[str]] = {};
    has dependents: dict[str, list[str]] = {};
    has required_skill: dict[str, str] = {};
    has agent_skills: dict[str, set[str]] = {};
    has nodes: dict[str, DecompTask] = {};
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has origin: str = "";

    can step with DecompTask entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid != self.origin { self.hits.append(here.tid); }
        visit [->:PrereqOf:->] else { disengage; };
    }
}

walker CycleProbe {
    has color: dict[str, int] = {};
    has has_cycle: bool = False;

    can probe with DecompTask entry {
        if self.has_cycle { skip; }
        c = self.color.get(here.tid, 0);
        if c == 2 { skip; }
        if c == 1 {
            self.has_cycle = True;
            skip;
        }
        self.color[here.tid] = 1;
        visit [<-:PrereqOf:<-] else { disengage; };
        self.color[here.tid] = 2;
    }
}

def load_decomposition_store(
    task_ids: list[str],
    depends: list[tuple[str, str]],
    skills: dict[str, str] | None = None,
    agents: dict[str, list[str]] | None = None,
) -> DecompStore {
    store = DecompStore();
    for tid in task_ids {
        store.tasks.add(tid);
        store.prereqs[tid] = [];
        store.dependents[tid] = [];
        nd = DecompTask(tid=tid);
        root ++> nd;
        store.nodes[tid] = nd;
    }
    for (blocker, dependent) in depends {
        if blocker in store.tasks and dependent in store.tasks {
            store.prereqs[dependent].append(blocker);
            store.dependents[blocker].append(dependent);
            blk = store.nodes.get(blocker, None);
            dep = store.nodes.get(dependent, None);
            if blk is not None and dep is not None { blk +>:PrereqOf:+> dep; }
        }
    }
    for tid in store.prereqs {
        store.prereqs[tid] = sorted(store.prereqs[tid]);
    }
    for tid in store.dependents {
        store.dependents[tid] = sorted(store.dependents[tid]);
    }
    skill_map = skills;
    if skill_map is None { skill_map = {}; }
    for (tid, skill) in skill_map.items() {
        if tid in store.tasks { store.required_skill[tid] = skill; }
    }
    agent_map = agents;
    if agent_map is None { agent_map = {}; }
    for (agent, caps) in agent_map.items() {
        cap_set: set[str] = set();
        for c in caps { cap_set.add(c); }
        store.agent_skills[agent] = cap_set;
    }
    return store;
}

def downstream_closure(store: DecompStore, task_id: str) -> list[str] {
    if task_id not in store.tasks { return []; }
    nd = store.nodes.get(task_id, None);
    if nd is None { return []; }
    w = nd spawn DownstreamWalk(claimed={}, hits=[], origin=task_id);
    return sorted(w.hits);
}

def parallel_waves(store: DecompStore) -> list[list[str]] {
    indeg: dict[str, int] = {};
    for t in store.tasks {
        indeg[t] = len(store.prereqs.get(t, []));
    }
    waves: list[list[str]] = [];
    ready: list[str] = [];
    for (t, d) in indeg.items() {
        if d == 0 { ready.append(t); }
    }
    ready = sorted(ready);
    visited: dict[str, bool] = {};
    while len(ready) > 0 {
        layer = ready;
        waves.append(layer);
        nxt: list[str] = [];
        for node in layer {
            visited[node] = True;
            others: list[str] = [];
            for t in store.tasks { others.append(t); }
            for other in others {
                if other in visited { continue; }
                prs = store.prereqs.get(other, []);
                blocked = False;
                for p in prs {
                    if p == node { blocked = True; }
                }
                if blocked {
                    indeg[other] -= 1;
                    if indeg[other] == 0 { nxt.append(other); }
                }
            }
        }
        ready = sorted(nxt);
    }
    if len(visited) != len(store.tasks) { return []; }
    return waves;
}

def ready_after(store: DecompStore, completed: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for c in completed { done[c] = True; }
    out: list[str] = [];
    keys: list[str] = [];
    for t in store.tasks { keys.append(t); }
    for tid in sorted(keys) {
        if tid in done { continue; }
        ok = True;
        for p in store.prereqs.get(tid, []) {
            if p not in done { ok = False; }
        }
        if ok { out.append(tid); }
    }
    return out;
}

def match_agents(store: DecompStore) -> dict[str, str] {
    assignment: dict[str, str] = {};
    tids: list[str] = [];
    for t in store.tasks { tids.append(t); }
    agents: list[str] = [];
    for a in store.agent_skills { agents.append(a); }
    for tid in sorted(tids) {
        need = store.required_skill.get(tid, "");
        if not need { continue; }
        for agent in sorted(agents) {
            caps = store.agent_skills.get(agent, set());
            if need in caps {
                assignment[tid] = agent;
                break;
            }
        }
    }
    return assignment;
}

def coverage_ratio(store: DecompStore, assignment: dict[str, str]) -> float {
    if len(store.tasks) == 0 { return 1.0; }
    matched = 0;
    for t in store.tasks {
        if t in assignment { matched += 1; }
    }
    return matched / len(store.tasks);
}

def _dfs_cycle_dnb(store: DecompStore, `node: str, w_vis: dict[str, bool], w_seen: dict[str, bool]) -> bool {
    if w_vis.get(`node, False) { return True; }
    if `node in w_seen { return False; }
    w_vis[`node] = True;
    for dep in store.prereqs.get(`node, []) {
        if _dfs_cycle_dnb(store, dep, w_vis, w_seen) { return True; }
    }
    w_vis[`node] = False;
    w_seen[`node] = True;
    return False;
}

def has_dependency_cycle(store: DecompStore) -> bool {
    w_seen: dict[str, bool] = {};
    for tid in sorted(store.tasks) {
        if tid in w_seen { continue; }
        w_vis: dict[str, bool] = {};
        if _dfs_cycle_dnb(store, tid, w_vis, w_seen) { return True; }
    }
    return False;
}
