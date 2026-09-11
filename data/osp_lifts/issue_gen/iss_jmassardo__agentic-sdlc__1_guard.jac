"""Guard: jmassardo/agentic-sdlc#1."""

node Agent { has name: str; }
edge Handoff {}

obj AgentStore { has agents: dict[str, Agent] = {}; }

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Agent entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Handoff:->][?:Agent];
    }
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with Agent entry {
        if here.name in self.visited { skip; }
        self.visited[here.name] = True;
        self.stack[here.name] = True;
        for nxt in [here ->:Handoff:->][?:Agent] {
            if nxt.name in self.stack {
                self.errors.append((here.name, nxt.name));
            } else {
                if not (nxt.name in self.visited) {
                    visit [nxt];
                }
            }
        }
        self.stack[here.name] = False;
    }
}

def load_agents(
    names: list[str],
    handoff_edges: list[tuple[str, str]],
) -> AgentStore {
    store = AgentStore();
    for name in names {
        nd = Agent(name=name);
        root ++> nd;
        store.agents[name] = nd;
    }
    for (src, dst) in handoff_edges {
        a = store.agents.get(src, None);
        b = store.agents.get(dst, None);
        if a is not None and b is not None { a +>:Handoff:+> b; }
    }
    return store;
}

def reachable_agents(store: AgentStore, start: str) -> list[str] {
    nd = store.agents.get(start, None);
    if nd is None { return []; }
    w = nd spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def detect_handoff_cycles(store: AgentStore) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(store.agents.keys()) {
        if k in visited { continue; }
        nd = store.agents[k];
        w = nd spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

test "orchestration reachability" {
    s = load_agents(
        ["dispatcher", "architecture", "development", "reviewer", "quality"],
        [
            ("dispatcher", "architecture"),
            ("architecture", "development"),
            ("development", "reviewer"),
            ("reviewer", "quality"),
            ("quality", "development"),
        ],
    );
    assert reachable_agents(s, "dispatcher") == [
        "architecture", "development", "dispatcher", "quality", "reviewer",
    ];
    assert detect_handoff_cycles(s) == [("quality", "development")];
}

test "diamond adversarial reach" {
    s = load_agents(
        ["hub", "a", "b", "tip"],
        [("hub", "a"), ("hub", "b"), ("a", "tip"), ("b", "tip")],
    );
    assert reachable_agents(s, "hub") == ["a", "b", "hub", "tip"];
}

test "unknown start tolerant" {
    s = load_agents(["solo"], []);
    assert reachable_agents(s, "ghost") == [];
}
