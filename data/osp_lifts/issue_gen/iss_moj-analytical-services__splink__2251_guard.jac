"""moj-analytical-services/splink#2251 — recursive link clustering via OSP graph walk."""

node Record {
    has rid: str;
}

node ClusterStore {
    has nodes: dict[str, Record] = {};
}

edge Match {}

walker CollectCluster {
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];

    can traverse with Record entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        self.members.append(here.rid);
        print(here.rid);
        nbrs: list[Record] = [here ->:Match:->][?:Record];
        if len(nbrs) > 0 {
            visit :0: nbrs;
        } else {
            disengage;
        }
    }
}

def create_cluster_store() -> ClusterStore {
    st = ClusterStore();
    root ++> st;
    st.nodes = {};
    return st;
}

def get_or_create_record(st: ClusterStore, rid: str) -> Record {
    if rid in st.nodes {
        return st.nodes[rid];
    }
    nd = Record(rid=rid);
    st +>:Match:+> nd;
    st.nodes[rid] = nd;
    return nd;
}

def add_links(st: ClusterStore, links: list[tuple[str, str]]) {
    for pair in links {
        left_id = pair[0];
        right_id = pair[1];
        left_nd = get_or_create_record(st, left_id);
        right_nd = get_or_create_record(st, right_id);
        left_nd +>:Match:+> right_nd;
        right_nd +>:Match:+> left_nd;
    }
}

def get_cluster_members(st: ClusterStore, seed_id: str) -> list[str] {
    if seed_id not in st.nodes {
        return [];
    }
    seed_nd = st.nodes[seed_id];
    w = seed_nd spawn CollectCluster(claimed={}, members=[]);
    out: list[str] = [];
    for m in w.members {
        out.append(m);
    }
    return sorted(out);
}

def cluster_all_records(st: ClusterStore) -> list[list[str]] {
    seen: dict[str, bool] = {};
    components: list[list[str]] = [];
    ids: list[str] = [];
    for rid in st.nodes.keys() {
        ids.append(rid);
    }
    ids = sorted(ids);
    for rid in ids {
        if rid in seen {
            continue;
        }
        w = st.nodes[rid] spawn CollectCluster(claimed={}, members=[]);
        comp: list[str] = [];
        for m in w.members {
            seen[m] = True;
            comp.append(m);
        }
        if len(comp) > 0 {
            components.append(sorted(comp));
        }
    }
    return sorted(components);
}

test "diamond_revisit_transitive_closure" {
    st = create_cluster_store();
    add_links(st, [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")]);
    got = get_cluster_members(st, "a");
    assert got == ["a", "b", "c", "d"];
}

test "unknown_seed_returns_empty" {
    st = create_cluster_store();
    got = get_cluster_members(st, "no_such_record");
    assert got == [];
}

test "disconnected_components_sorted" {
    st = create_cluster_store();
    add_links(st, [("a", "b"), ("c", "d")]);
    got = cluster_all_records(st);
    assert got == [["a", "b"], ["c", "d"]];
}

test "empty_store_yields_no_components" {
    st = create_cluster_store();
    assert cluster_all_records(st) == [];
}

test "self_link_single_member_cluster" {
    st = create_cluster_store();
    add_links(st, [("solo", "solo")]);
    assert get_cluster_members(st, "solo") == ["solo"];
    assert cluster_all_records(st) == [["solo"]];
}
