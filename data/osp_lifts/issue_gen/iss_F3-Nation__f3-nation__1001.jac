"""F3-Nation/f3-nation#1001 — depth-agnostic org ancestry for pv_* materializations."""

node org {
    has oid: str;
    has org_type: str;
    has name: str = "";
}

edge parent {}

walker OrgLocator {
    has want: str = "";
    has claimed: dict[str, bool] = {};
    has hit: org | None = None;

    can seek with org entry {
        if here.oid in self.claimed { skip; }
        self.claimed[here.oid] = True;
        if here.oid == self.want {
            self.hit = here;
            disengage;
        }
        nbrs: list[org] = [here <-->][?:org];
        if nbrs { visit :0: nbrs; } else { disengage; }
    }
}

walker AncestorResolver {
    has target_type: str = "";
    has claimed: dict[str, bool] = {};
    has found_oid: str = "";
    has found_name: str = "";

    can climb with org entry {
        if here.oid in self.claimed { skip; }
        self.claimed[here.oid] = True;
        if here.org_type == self.target_type {
            self.found_oid = here.oid;
            self.found_name = here.name;
            disengage;
        }
        ups: list[org] = [here ->:parent:->][?:org];
        if ups { visit :0: ups; } else { disengage; }
    }
}

walker DescendantTyper {
    has target_type: str = "";
    has origin_oid: str = "";
    has claimed: dict[str, bool] = {};
    has tally: int = 0;

    can descend with org entry {
        if here.oid in self.claimed { skip; }
        self.claimed[here.oid] = True;
        if here.oid != self.origin_oid and here.org_type == self.target_type {
            self.tally += 1;
        }
        kids: list[org] = [here <-:parent:<-][?:org];
        if kids { visit :0: kids; } else { disengage; }
    }
}

walker BootProbe {
    has claimed: dict[str, bool] = {};

    can ping with org entry {
        if here.oid in self.claimed { skip; }
        self.claimed[here.oid] = True;
        print("boot", here.oid);
        disengage;
    }
}

def make_anchor() -> org {
    anchor = org(oid="__anchor__", org_type="anchor", name="");
    return anchor;
}

def attach(anchor: org, nd: org) -> None {
    anchor ++> nd;
}

def link_child_parent(child: org, par: org) -> None {
    child +>:parent:+> par;
}

def find_org(graph_root: org, oid: str) -> org | None {
    w = graph_root spawn OrgLocator(want=oid, claimed={});
    print("locate", oid, w.hit is not None);
    return w.hit;
}

def resolve_ancestor_id(graph_root: org, start_id: str, tier_type: str) -> str | None {
    start_node = find_org(graph_root, start_id);
    if start_node is None { return None; }
    w = start_node spawn AncestorResolver(target_type=tier_type, claimed={});
    print("ancestor_id", start_id, tier_type, w.found_oid);
    if w.found_oid == "" { return None; }
    return w.found_oid;
}

def resolve_ancestor_name(graph_root: org, start_id: str, tier_type: str) -> str | None {
    start_node = find_org(graph_root, start_id);
    if start_node is None { return None; }
    w = start_node spawn AncestorResolver(target_type=tier_type, claimed={});
    print("ancestor_name", start_id, tier_type, w.found_name);
    if w.found_oid == "" { return None; }
    return w.found_name;
}

def flatten_tiers(graph_root: org, start_id: str) -> dict[str, str | None] {
    out: dict[str, str | None] = {};
    tiers: list[str] = ["sector", "territory", "area", "region"];
    for tier in tiers {
        out[tier + "_id"] = resolve_ancestor_id(graph_root, start_id, tier);
        out[tier + "_name"] = resolve_ancestor_name(graph_root, start_id, tier);
    }
    print("flatten", start_id);
    return out;
}

def count_descendants_by_type(graph_root: org, start_id: str, target_type: str) -> int {
    start_node = find_org(graph_root, start_id);
    if start_node is None { return 0; }
    w = start_node spawn DescendantTyper(
        target_type=target_type, origin_oid=start_id, claimed={}
    );
    print("count_desc", start_id, target_type, w.tally);
    return w.tally;
}

with entry {
    seed = org(oid="boot", org_type="anchor", name="");
    root ++> seed;
    w = root spawn BootProbe(claimed={});
}
