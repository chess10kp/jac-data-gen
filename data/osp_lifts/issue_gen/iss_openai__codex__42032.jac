"""Recursive subagent lifecycle — openai/codex#42032."""

node Agent {
    has cid: str;
    has state: str = "running";
    has quota_used: int = 0;
}

edge Delegates {}

walker FindAgent {
    has target: str;
    has found: Agent | None = None;
    has claimed: dict[str, bool] = {};
    can seek with Agent entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.found = here;
            print("found", here.cid);
            disengage;
        }
        kids: list[Agent] = [here ->:Delegates:->][?:Agent];
        for ch in kids {
            visit :0: [ch];
        }
        print("seek", here.cid);
    }
}

walker CountDesc {
    has claimed: dict[str, bool] = {};
    has count: int = 0;
    can tally with Agent entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.count += 1;
        kids: list[Agent] = [here ->:Delegates:->][?:Agent];
        for ch in kids {
            visit :0: [ch];
        }
        print("tally", here.cid, self.count);
    }
}

walker CollectAgents {
    has claimed: dict[str, bool] = {};
    has nodes: list[Agent] = [];
    can gather with Agent entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.nodes.append(here);
        kids: list[Agent] = [here ->:Delegates:->][?:Agent];
        for ch in kids {
            visit :0: [ch];
        }
        print("gather", here.cid);
    }
}

walker CollectRunning {
    has claimed: dict[str, bool] = {};
    has root_id: str = "";
    has ids: list[str] = [];
    can harvest with Agent entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.state == "running" and here.cid != self.root_id {
            self.ids.append(here.cid);
        }
        kids: list[Agent] = [here ->:Delegates:->][?:Agent];
        for ch in kids {
            visit :0: [ch];
        }
        print("harvest", here.cid);
    }
}

walker LifecycleDemo {
    has claimed: dict[str, bool] = {};
    can start {
        tops: list[Agent] = [-->][?:Agent];
        for t in tops {
            visit :0: [t];
        }
    }
    can demo with Agent entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("demo", here.cid, here.state);
        kids: list[Agent] = [here ->:Delegates:->][?:Agent];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

def find_agent(cid: str) -> Agent | None {
    tops: list[Agent] = [root -->][?:Agent];
    for top in tops {
        w: FindAgent = top spawn FindAgent(target=cid, claimed={});
        if w.found is not None {
            return w.found;
        }
    }
    return None;
}

def create_coordinator(coord_id: str) -> str {
    coord: Agent = Agent(cid=coord_id);
    root ++> coord;
    print("create_coordinator", coord_id);
    return coord_id;
}

def delegate(parent_cid: str, child_cid: str) -> bool {
    parent: Agent | None = find_agent(parent_cid);
    if parent is None { return False; }
    existing: Agent | None = find_agent(child_cid);
    if existing is not None { return False; }
    child: Agent = Agent(cid=child_cid);
    parent +>:Delegates:+> child;
    print("delegate", parent_cid, child_cid);
    return True;
}

def complete_agent(cid: str) -> bool {
    agent: Agent | None = find_agent(cid);
    if agent is None { return False; }
    agent.state = "completed";
    print("complete", cid);
    return True;
}

def count_descendants(coord_cid: str) -> int {
    coord: Agent | None = find_agent(coord_cid);
    if coord is None { return 0; }
    w: CountDesc = coord spawn CountDesc(claimed={});
    return w.count - 1;
}

def cancel_recursive(coord_cid: str) -> list[str] {
    coord: Agent | None = find_agent(coord_cid);
    if coord is None { return []; }
    w: CollectAgents = coord spawn CollectAgents(claimed={});
    cancelled: list[str] = [];
    for nd in w.nodes {
        if nd.state == "running" {
            nd.state = "cancelled";
            cancelled.append(nd.cid);
        }
    }
    cancelled.sort();
    print("cancel_recursive", coord_cid, len(cancelled));
    return cancelled;
}

def running_orphans(coord_cid: str) -> list[str] {
    coord: Agent | None = find_agent(coord_cid);
    if coord is None { return []; }
    if coord.state != "completed" { return []; }
    w: CollectRunning = coord spawn CollectRunning(claimed={}, root_id=coord_cid);
    out: list[str] = [];
    for cid in w.ids {
        out.append(cid);
    }
    out.sort();
    return out;
}

def within_delegation_budget(coord_cid: str, max_total: int) -> bool {
    total: int = count_descendants(coord_cid);
    return total < max_total;
}

with entry {
    root spawn LifecycleDemo(claimed={});
}
