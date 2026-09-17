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
