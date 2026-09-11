"""Guard: chris-dev-at/BetterTrack#660."""

obj PortfolioStore {
    has ports: dict[str, Portfolio] = {};
    has depth_cap: int = 3;
}

node Portfolio { has pid: str; }
edge Nests {}

walker FlattenWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Portfolio entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.reached.append(here.pid);
        visit [->:Nests:->] else { disengage; };
    }
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has depth_cap: int = 0;
    has depth: dict[str, int] = {};

    can step with Portfolio entry {
        if here.pid in self.claimed { skip; }
        cur_d = self.depth.get(here.pid, 0);
        if cur_d > self.depth_cap { disengage; }
        self.claimed[here.pid] = True;
        self.reached.append(here.pid);
        for nxt in [here ->:Nests:->][?:Portfolio] {
            nd = cur_d + 1;
            if nd <= self.depth_cap {
                self.depth[nxt.pid] = nd;
                visit [nxt];
            }
        }
    }
}

def load_portfolios(
    portfolios: list[str],
    nest_links: list[tuple[str, str]],
    depth_cap: int = 3,
) -> PortfolioStore {
    s = PortfolioStore(depth_cap=depth_cap);
    for pid in portfolios {
        if pid not in s.ports {
            nd = Portfolio(pid=pid);
            root ++> nd;
            s.ports[pid] = nd;
        }
    }
    for (parent, child) in nest_links {
        p = s.ports.get(parent, None);
        c = s.ports.get(child, None);
        if p is not None and c is not None { p +>:Nests:+> c; }
    }
    return s;
}

def would_create_cycle(store: PortfolioStore, parent: str, child: str) -> bool {
    if parent not in store.ports or child not in store.ports { return False; }
    if parent == child { return True; }
    anchor = store.ports[child];
    w = anchor spawn ReachWalk(
        claimed={},
        reached=[],
        depth_cap=store.depth_cap,
        depth={child: 0},
    );
    for pid in w.reached {
        if pid == parent { return True; }
    }
    return False;
}

def flattened_portfolios(store: PortfolioStore, root_id: str) -> list[str] {
    anchor = store.ports.get(root_id, None);
    if anchor is None { return []; }
    w = anchor spawn FlattenWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

test "double-count diamond flattened once" {
    s = load_portfolios(
        ["D", "C", "A"],
        [("D", "C"), ("C", "A"), ("D", "A")],
    );
    assert flattened_portfolios(s, "D") == ["A", "C", "D"];
}

test "cycle guard on proposed nest link" {
    s = load_portfolios(["P", "Q"], [("P", "Q")]);
    assert would_create_cycle(s, "Q", "P") is True;
    assert would_create_cycle(s, "P", "Q") is False;
}

test "diamond adversarial flatten order" {
    s = load_portfolios(
        ["hub", "left", "right", "leaf"],
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    );
    assert flattened_portfolios(s, "hub") == ["hub", "leaf", "left", "right"];
}

test "depth cap limits cycle probe reach" {
    s = load_portfolios(
        ["a", "b", "c", "d", "e"],
        [("a", "b"), ("b", "c"), ("c", "d"), ("d", "e")],
        depth_cap=2,
    );
    assert would_create_cycle(s, "e", "a") is False;
}

test "unknown portfolio tolerant" {
    s = load_portfolios(["solo"], []);
    assert flattened_portfolios(s, "missing") == [];
}
