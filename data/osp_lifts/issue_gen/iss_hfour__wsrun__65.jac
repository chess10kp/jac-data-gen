"""hfour/wsrun#65 — optionally disable cycle detection."""

node Workspace {
    has name: str;
}

edge Depends {}

obj GraphHandle {
    has nodes: dict[str, Workspace] = {};
}

walker RunWalker {
    has claimed: dict[str, bool] = {};
    has stack: list[str] = [];
    has order: list[str] = [];
    has cycle: list[str] = [];
    has no_cycle_detection: bool = False;

    can step with Workspace entry {
        if here.name in self.claimed {
            if not self.no_cycle_detection and len(self.cycle) == 0 {
                cyc: list[str] = [];
                seen_start: bool = False;
                for nm in self.stack {
                    if nm == here.name {
                        seen_start = True;
                    }
                    if seen_start {
                        cyc.append(nm);
                    }
                }
                cyc.append(here.name);
                self.cycle = cyc;
            }
            skip;
        }
        self.claimed[here.name] = True;
        self.stack.append(here.name);
        self.order.append(here.name);
        print("visit ", here.name);
        kids: list[Workspace] = [here ->:Depends:->][?:Workspace];
        if len(kids) > 0 {
            for kid in kids {
                visit :0: [kid];
            }
        }
        if len(self.stack) > 0 {
            top_ix = len(self.stack) - 1;
            if self.stack[top_ix] == here.name {
                self.stack.pop();
            }
        }
    }
}

def _build_graph(deps: dict[str, list[str]]) -> GraphHandle {
    gh = GraphHandle();
    names: list[str] = sorted(deps.keys());
    for nm in names {
        ws = Workspace(name=nm);
        root ++> ws;
        gh.nodes[nm] = ws;
    }
    for nm in names {
        src = gh.nodes[nm] as Workspace;
        dep_names: list[str] = deps[nm];
        for dn in dep_names {
            if dn in gh.nodes {
                dst = gh.nodes[dn] as Workspace;
                src +>:Depends:+> dst;
            }
        }
    }
    return gh;
}

def traverse(
    deps: dict[str, list[str]],
    roots: list[str],
    no_cycle_detection: bool = False,
) -> dict {
    gh = _build_graph(deps);
    merged_order: list[str] = [];
    merged_cycle: list[str] = [];
    got_cycle: bool = False;
    for rn in sorted(roots) {
        if rn not in gh.nodes {
            continue;
        }
        nd = gh.nodes[rn] as Workspace;
        w = nd spawn RunWalker(
            claimed={},
            no_cycle_detection=no_cycle_detection,
        );
        print("spawn ", rn);
        for x in w.order {
            merged_order.append(x);
        }
        if len(w.cycle) > 0 and not got_cycle {
            merged_cycle = w.cycle;
            got_cycle = True;
        }
    }
    res: dict = {};
    res["order"] = merged_order;
    res["cycle"] = None;
    if got_cycle {
        res["cycle"] = merged_cycle;
    }
    return res;
}
