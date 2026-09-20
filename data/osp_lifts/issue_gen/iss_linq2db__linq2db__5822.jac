"""linq2db/linq2db#5822 — recursive UNION CTE outer projection emission."""

node Cte {
    has cid: str;
    has body_kind: str;
    has outer_proj: bool = False;
}

node Leg {
    has cid: str;
    has role: str;
}

edge Recurse {}
edge LegLink {}
edge Wrap {}

walker ReachW {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step_cte with Cte entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        leg_kids: list[Leg] = [];
        for ch in [here ->:LegLink:->][?:Leg] {
            leg_kids.append(ch);
        }
        cte_kids: list[Cte] = [];
        for ch in [here ->:Recurse:->][?:Cte] {
            cte_kids.append(ch);
        }
        if leg_kids {
            visit :0: leg_kids;
        }
        if cte_kids {
            visit :0: cte_kids;
        }
        if not leg_kids and not cte_kids {
            disengage;
        }
    }

    can step_leg with Leg entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        leg_kids: list[Leg] = [];
        for ch in [here ->:LegLink:->][?:Leg] {
            leg_kids.append(ch);
        }
        cte_kids: list[Cte] = [];
        for ch in [here ->:Recurse:->][?:Cte] {
            cte_kids.append(ch);
        }
        if leg_kids {
            visit :0: leg_kids;
        }
        if cte_kids {
            visit :0: cte_kids;
        }
        if not leg_kids and not cte_kids {
            disengage;
        }
    }
}

walker ValidW {
    has claimed: dict[str, bool] = {};
    has valid: bool = True;

    can check_cte with Cte entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print(here.cid);
        if here.body_kind == "union" and here.outer_proj {
            for wn in [here ->:Wrap:->][?:Leg] {
                self.valid = False;
            }
        }
        leg_kids: list[Leg] = [];
        for ch in [here ->:LegLink:->][?:Leg] {
            leg_kids.append(ch);
        }
        cte_kids: list[Cte] = [];
        for ch in [here ->:Recurse:->][?:Cte] {
            cte_kids.append(ch);
        }
        if leg_kids {
            visit :0: leg_kids;
        }
        if cte_kids {
            visit :0: cte_kids;
        }
        if not leg_kids and not cte_kids {
            disengage;
        }
    }

    can check_leg with Leg entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print(here.cid);
        leg_kids: list[Leg] = [];
        for ch in [here ->:LegLink:->][?:Leg] {
            leg_kids.append(ch);
        }
        cte_kids: list[Cte] = [];
        for ch in [here ->:Recurse:->][?:Cte] {
            cte_kids.append(ch);
        }
        if leg_kids {
            visit :0: leg_kids;
        }
        if cte_kids {
            visit :0: cte_kids;
        }
        if not leg_kids and not cte_kids {
            disengage;
        }
    }
}

def new_store() -> dict[str, object] {
    st: dict[str, object] = {};
    return st;
}

def add_recursive_cte(
    store: dict[str, object],
    cte_id: str,
    body_kind: str,
    outer_proj: bool
) -> None {
    c = Cte(cid=cte_id, body_kind=body_kind, outer_proj=outer_proj);
    anchor = Leg(cid=cte_id + ":anchor", role="anchor");
    recur = Leg(cid=cte_id + ":recur", role="recursive");
    store[cte_id] = c;
    root ++> c;
    c +>:LegLink:+> anchor;
    c +>:LegLink:+> recur;
    recur +>:Recurse:+> c;
    if body_kind == "union" and outer_proj {
        wrap = Leg(cid=cte_id + ":wrap", role="derived");
        c +>:Wrap:+> wrap;
    }
}

def add_cycle_diamond(store: dict[str, object], cte_id: str) -> None {
    c = Cte(cid=cte_id, body_kind="union_all", outer_proj=False);
    la = Leg(cid=cte_id + ":a", role="fork_a");
    lb = Leg(cid=cte_id + ":b", role="fork_b");
    mid = Leg(cid=cte_id + ":mid", role="join");
    store[cte_id] = c;
    root ++> c;
    c +>:LegLink:+> lb;
    c +>:LegLink:+> la;
    la +>:LegLink:+> mid;
    lb +>:LegLink:+> mid;
    mid +>:Recurse:+> c;
}

def projection_fold_allowed(body_kind: str, outer_proj: bool) -> bool {
    if not outer_proj {
        return True;
    }
    if body_kind == "union_all" {
        return True;
    }
    return False;
}

def reachable_ids(store: dict[str, object], cte_id: str) -> list[str] {
    if cte_id not in store {
        return [];
    }
    c = store[cte_id] as Cte;
    w = c spawn ReachW(claimed={});
    print(len(w.found));
    out: list[str] = sorted(w.found);
    return out;
}

def emission_valid(store: dict[str, object], cte_id: str) -> bool {
    if cte_id not in store {
        return False;
    }
    c = store[cte_id] as Cte;
    w = c spawn ValidW(claimed={});
    print(w.valid);
    return w.valid;
}

def emission_tokens(store: dict[str, object], cte_id: str) -> list[str] {
    if cte_id not in store {
        return [];
    }
    c = store[cte_id] as Cte;
    toks: list[str] = [];
    toks.append("body:" + c.body_kind);
    if c.outer_proj {
        toks.append("outer_proj");
    }
    wrap_hit = False;
    for wn in [c ->:Wrap:->][?:Leg] {
        wrap_hit = True;
    }
    if wrap_hit {
        toks.append("derived_wrap");
    }
    if projection_fold_allowed(c.body_kind, c.outer_proj) {
        toks.append("fold_permitted");
    } else {
        toks.append("fold_denied");
    }
    if emission_valid(store, cte_id) {
        toks.append("valid");
    } else {
        toks.append("circular_ref");
    }
    out: list[str] = sorted(toks);
    return out;
}
