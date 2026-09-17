# Recursive subagent listing for openclaw/openclaw#47320
# Leader (depth-0) -> PM (depth-1) -> experts (depth-2); list with depth/recursive.

node Agent {
    has key: str;
    has label: str;
    has status: str = "idle";
    has model: str = "default";
    has runtime_ms: int = 0;
    has depth: int = 0;
}

edge SPAWNED { }

# find an agent by session key; None if unknown
def find_agent(key: str) -> Agent | None {
    for nd in [root -->] {
        if nd is Agent and nd.key == key { return nd; }
    }
    return None;
}

# BFS from start, bounded by depth_limit (-1 = unlimited), claim-map cycle policy
def list_subagents(key: str, depth_limit: int) -> list[dict] | None {
    start = find_agent(key);
    if start is None { return None; }
    rows: list[dict] = [];
    claimed: dict[str, bool] = {key: True};
    frontier: list[tuple[Agent, int]] = [(start, 0)];
    while len(frontier) > 0 {
        cur, d = frontier.pop(0);
        if d > 0 {
            rows.append({
                "key": cur.key,
                "label": cur.label,
                "status": cur.status,
                "model": cur.model,
                "runtime": cur.runtime_ms,
                "parent": parent_key(cur),
                "depth": d,
            });
        }
        if depth_limit >= 0 and d >= depth_limit { continue; }
        for ch in [cur ->:SPAWNED:->] {
            if ch.key in claimed { continue; }
            claimed[ch.key] = True;
            frontier.append((ch, d + 1));
        }
    }
    return sort_rows(rows);
}

# locate parent session key via reverse edge
def parent_key(nd: Agent) -> str {
    for par in [nd <-:SPAWNED:-] {
        if par is Agent { return par.key; }
    }
    return "";
}

# deterministic ordering: depth then key (two stable sorts, no tuple lambda)
def sort_rows(rows: list[dict]) -> list[dict] {
    out = sorted(rows, key=lambda r: r["key"]);
    return sorted(out, key=lambda r: r["depth"]);
}

# spawn a child agent under parent
def spawn_child(parent: Agent, child: Agent) {
    parent +>:SPAWNED:+> child;
    child.depth = parent.depth + 1;
}

walker Demo {
    can go with root entry {
        leader = Agent(key="s0", label="Leader", status="running", depth=0);
        root ++> leader;
        pm = Agent(key="s1", label="PM", status="running");
        spawn_child(leader, pm);
        e1 = Agent(key="s2", label="Expert-A", status="done", runtime_ms=1200);
        e2 = Agent(key="s3", label="Expert-B", status="stuck", runtime_ms=9900);
        spawn_child(pm, e1);
        spawn_child(pm, e2);
        rows = list_subagents("s0", 2);
        print(rows);
        rec = list_subagents("s0", -1);
        print(rec);
        print(list_subagents("nope", 3));
        disengage;
    }
}

with entry {
    root spawn Demo();
}
