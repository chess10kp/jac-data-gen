# mattpocock/skills#573 — recursive /code-review fan-out guard
# Agents form a spawn tree; only orchestrator-level invocations may fan out.
node Agent {
    has aid: str;
    has role: str;
    has spawned: int = 0;
    has banned: bool = False;
}
edge INVOKED {}

glob registry: dict[str, Agent] = {};

def make_agent(aid: str, role: str) -> Agent {
    a = Agent(aid=aid, role=role, banned=(role != "orchestrator"));
    registry[aid] = a;
    return a;
}

def link(parent: str, child: str) {
    p = registry[parent];
    c = registry[child];
    p +>:INVOKED:+> c;
}

def get_agent(aid: str) -> Agent | None {
    if aid in registry {
        return registry[aid];
    }
    return None;
}

def invoke_code_review(root_id: str) -> list[str] {
    # BFS fan-out from the invoking agent; banned agents cannot delegate.
    start = get_agent(root_id);
    if start is None {
        return [];
    }
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    frontier: list[Agent] = [start];
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        if cur.aid in claimed {
            continue;
        }
        claimed[cur.aid] = True;
        for ch in [cur ->:INVOKED:->] {
            if ch.aid not in claimed {
                if ch.banned {
                    order.append(ch.aid);
                } else {
                    cur.spawned += 1;
                    order.append(ch.aid);
                    frontier.append(ch);
                }
            }
        }
    }
    return sorted(order);
}

walker Audit {
    has claimed: dict[str, bool] = {};
    has delegates: int = 0;
    can step with Agent entry {
        if here.aid in self.claimed {
            skip;
        }
        self.claimed[here.aid] = True;
        if here.spawned > 0 {
            self.delegates += 1;
        }
        kids: list[Agent] = [];
        for ch in [here ->:INVOKED:->] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            visit [] else { disengage; }
        }
        visit kids;
    }
}

with entry {
    top = make_agent("top", "orchestrator");
    st = make_agent("standards", "reviewer");
    sp = make_agent("spec", "reviewer");
    link("top", "standards");
    link("top", "spec");
    out = invoke_code_review("top");
    print("spawned:", out);
    au = top spawn Audit(claimed={});
    print("delegating nodes:", au.delegates);
    print("unknown:", invoke_code_review("ghost"));
}

test "diamond revisit terminates" {
    a1 = make_agent("d0", "orchestrator");
    b1 = make_agent("d1", "reviewer");
    b2 = make_agent("d2", "reviewer");
    c1 = make_agent("d3", "reviewer");
    link("d0", "d1");
    link("d0", "d2");
    link("d1", "d3");
    link("d2", "d3");
    r = invoke_code_review("d0");
    assert sorted(r) == ["d1", "d2", "d3"];
}

test "unknown id tolerated" {
    assert len(invoke_code_review("nope-404")) == 0;
    assert get_agent("nope-404") is None;
}

test "reviewers cannot re-fan-out" {
    o = make_agent("o1", "orchestrator");
    r1 = make_agent("r1", "reviewer");
    r2 = make_agent("r2", "reviewer");
    link("o1", "r1");
    link("o1", "r2");
    out = invoke_code_review("o1");
    assert sorted(out) == ["r1", "r2"];
    assert get_agent("o1").spawned == 2;
    assert get_agent("r1").spawned == 0;
}

test "single agent no spawn" {
    make_agent("solo", "orchestrator");
    assert invoke_code_review("solo") == [];
}

test "duplicate link no double count" {
    p = make_agent("p1", "orchestrator");
    q = make_agent("q1", "reviewer");
    link("p1", "q1");
    link("p1", "q1");
    out = invoke_code_review("p1");
    assert out == ["q1"];
    assert get_agent("p1").spawned == 1;
}
