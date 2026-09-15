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

test "diamond_revisit_counts_area_once" {
    anchor = make_anchor();
    top = org(oid="top", org_type="sector", name="Top");
    left = org(oid="l", org_type="region", name="L");
    right = org(oid="r", org_type="region", name="R");
    area = org(oid="a1", org_type="area", name="A");
    attach(anchor, top);
    attach(anchor, left);
    attach(anchor, right);
    attach(anchor, area);
    link_child_parent(left, top);
    link_child_parent(right, top);
    link_child_parent(area, left);
    link_child_parent(area, right);
    assert count_descendants_by_type(anchor, "top", "area") == 1;
}

test "sector_areas_via_ancestry_not_direct_child" {
    anchor = make_anchor();
    s9 = org(oid="s9", org_type="sector", name="S9");
    terr = org(oid="t1", org_type="territory", name="T1");
    ar = org(oid="ar1", org_type="area", name="AR1");
    attach(anchor, s9);
    attach(anchor, terr);
    attach(anchor, ar);
    link_child_parent(terr, s9);
    link_child_parent(ar, terr);
    assert count_descendants_by_type(anchor, "s9", "area") == 1;
}

test "resolve_sector_through_territory_layer" {
    anchor = make_anchor();
    ao = org(oid="ao1", org_type="ao", name="AO");
    reg = org(oid="rg1", org_type="region", name="RG");
    area = org(oid="ar2", org_type="area", name="AR");
    terr = org(oid="tr2", org_type="territory", name="TR");
    sec = org(oid="sc2", org_type="sector", name="SC");
    attach(anchor, ao);
    attach(anchor, reg);
    attach(anchor, area);
    attach(anchor, terr);
    attach(anchor, sec);
    link_child_parent(ao, reg);
    link_child_parent(reg, area);
    link_child_parent(area, terr);
    link_child_parent(terr, sec);
    assert resolve_ancestor_id(anchor, "ao1", "sector") == "sc2";
    assert resolve_ancestor_name(anchor, "ao1", "territory") == "TR";
}

test "flatten_tiers_includes_territory_and_sector" {
    anchor = make_anchor();
    ao = org(oid="ao9", org_type="ao", name="AO9");
    reg = org(oid="rg9", org_type="region", name="RG9");
    area = org(oid="ar9", org_type="area", name="AR9");
    terr = org(oid="tr9", org_type="territory", name="TR9");
    sec = org(oid="sc9", org_type="sector", name="SC9");
    attach(anchor, ao);
    attach(anchor, reg);
    attach(anchor, area);
    attach(anchor, terr);
    attach(anchor, sec);
    link_child_parent(ao, reg);
    link_child_parent(reg, area);
    link_child_parent(area, terr);
    link_child_parent(terr, sec);
    flat = flatten_tiers(anchor, "ao9");
    assert flat["territory_id"] == "tr9";
    assert flat["sector_id"] == "sc9";
    assert flat["sector_name"] == "SC9";
}

test "unknown_start_id_tolerant" {
    anchor = make_anchor();
    lone = org(oid="only", org_type="region", name="Only");
    attach(anchor, lone);
    assert count_descendants_by_type(anchor, "missing", "area") == 0;
    assert resolve_ancestor_id(anchor, "missing", "sector") is None;
    assert resolve_ancestor_name(anchor, "nope", "territory") is None;
}
