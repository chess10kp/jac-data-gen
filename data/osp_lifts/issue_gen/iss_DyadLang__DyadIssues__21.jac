# Lift of DyadLang/DyadIssues#21 — SFC flow-graph policy analysis.
# Sector-flow graph: reach, multiplier, lag over a stock-flow consistent network.

node Sector {
    has name: str;
    has wealth: float = 0.0;
}

edge Flow {
    has magnitude: float = 1.0;
    has lag: int = 1;
}

# BFS closure over Flow edges, claim-map cycle guard.
def reach(src: Sector) -> list[str] {
    seen: dict[str, bool] = {};
    frontier: list[Sector] = [src];
    while len(frontier) > 0 {
        cur: Sector = frontier.pop(0);
        if cur.name in seen { continue; }
        seen[cur.name] = True;
        for ch in [cur ->:Flow:->][?:Sector] {
            frontier.append(ch);
        }
    }
    return sorted(seen.keys());
}

# Adjacency map name -> sorted successor names (BFS, no revisits).
def adjacency(src: Sector) -> dict[str, list[str]] {
    res: dict[str, list[str]] = {};
    seen: dict[str, bool] = {};
    frontier: list[Sector] = [src];
    while len(frontier) > 0 {
        cur: Sector = frontier.pop(0);
        if cur.name in seen { continue; }
        seen[cur.name] = True;
        nb: list[str] = [];
        for ch in [cur ->:Flow:->][?:Sector] {
            nb.append(ch.name);
            frontier.append(ch);
        }
        res[cur.name] = sorted(nb);
    }
    return res;
}

# Multiplier: total flow magnitude in closure / direct first-hop magnitude.
def multiplier(src: Sector) -> float {
    direct: float = 0.0;
    total: float = 0.0;
    seen: dict[str, bool] = {};
    frontier: list[Sector] = [src];
    while len(frontier) > 0 {
        cur: Sector = frontier.pop(0);
        if cur.name in seen { continue; }
        seen[cur.name] = True;
        for e in [cur ->:Flow:->] {
            tgts: list[Sector] = [e ->][?:Sector];
            for ch in tgts {
                total += e.magnitude;
                if len(seen) == 1 and ch is not None and seen.get(cur.name, False) and not (ch.name in seen) {
                    # first wave only when src still sole-seen is fragile; count via depth below
                }
                frontier.append(ch);
            }
        }
    }
    for ch in [src ->:Flow:->][?:Sector] {
        direct += 1.0;
    }
    if direct == 0.0 { return 0.0; }
    return total / direct;
}

# Lag: mean edge lag across the reachable closure (0.0 for isolated).
def lag(src: Sector) -> float {
    total: int = 0;
    count: int = 0;
    seen: dict[str, bool] = {};
    frontier: list[Sector] = [src];
    while len(frontier) > 0 {
        cur: Sector = frontier.pop(0);
        if cur.name in seen { continue; }
        seen[cur.name] = True;
        for e in [cur ->:Flow:->] {
            total += e.lag;
            count += 1;
            for ch in [e ->][?:Sector] {
                frontier.append(ch);
            }
        }
    }
    if count == 0 { return 0.0; }
    return total / count;
}

walker PolicyProbe {
    has claimed: dict[str, bool] = {};
    has reach_list: list[str] = [];
    has mult: float = 0.0;
    has avg_lag: float = 0.0;
    has adj: dict[str, list[str]] = {};
    has iso_mult: float = 0.0;
    has iso_reach: list[str] = [];
    has hits: dict[str, int] = {};

    can start with root entry {
        a: Sector = Sector(name="gov");
        b: Sector = Sector(name="hh");
        c: Sector = Sector(name="firms");
        d: Sector = Sector(name="banks");
        e: Sector = Sector(name="ext");
        iso: Sector = Sector(name="isolated");
        root ++> a;
        # adversarial diamond: c's path reaches e first, d revisits e
        a +>:Flow:+> c;
        a +>:Flow:+> d;
        c +>:Flow:+> e;
        d +>:Flow:+> e;
        visit [a, b, iso];
    }

    can step with Sector entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.hits[here.name] = self.hits.get(here.name, 0) + 1;
        here.wealth += 1.0;
        if here.name == "gov" {
            self.reach_list = reach(here);
            self.mult = multiplier(here);
            self.avg_lag = lag(here);
            self.adj = adjacency(here);
        }
        if here.name == "isolated" {
            self.iso_mult = multiplier(here);
            self.iso_reach = reach(here);
        }
        kids: list[Sector] = [here ->:Flow:->][?:Sector];
        visit kids else { disengage; }
    }
}
