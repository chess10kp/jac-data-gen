"""payloadcms/payload#17658 — subtree walk excludes descendants for parent picker."""

node Doc {
    has id: str;
    has title: str;
}

edge Parent {}

walker SubtreeWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin_id: str = "";
    can descend with Doc entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        print("subtree ", here.id);
        if here.id != self.origin_id {
            self.found.append(here.id);
        }
        kids: list[Doc] = [];
        for ch in [here ->:Parent:->][?:Doc] {
            kids.append(ch);
        }
        for kid in kids {
            visit :0: kid;
        }
    }
}

def make_doc(doc_id: str, title: str) -> Doc {
    nd = Doc(id=doc_id, title=title);
    return nd;
}

def register_doc(store: dict[str, Doc], nd: Doc) -> Doc {
    store[nd.id] = nd;
    return nd;
}

def connect_parent(parent: Doc, child: Doc) {
    parent +>:Parent:+> child;
}

def broken_breadcrumb_not_in_match(editing_id: str, breadcrumb_docs: list[str]) -> bool {
    # Broken Postgres semantics: not_in matches when ANY breadcrumb row differs from editing_id.
    for row_doc in breadcrumb_docs {
        if row_doc != editing_id {
            return True;
        }
    }
    return False;
}

def collect_descendant_ids(editing_id: str, store: dict[str, Doc]) -> list[str] {
    if editing_id not in store {
        empty: list[str] = [];
        return empty;
    }
    origin = store[editing_id];
    w = origin spawn SubtreeWalk(claimed={}, origin_id=editing_id);
    return sorted(w.found);
}

def build_excluded_ids(editing_id: str, store: dict[str, Doc]) -> list[str] {
    excluded: list[str] = [editing_id];
    desc = collect_descendant_ids(editing_id, store);
    for d in desc {
        excluded.append(d);
    }
    return sorted(excluded);
}

def filter_parent_candidates(editing_id: str, candidates: list[str], store: dict[str, Doc]) -> list[str] {
    ex = build_excluded_ids(editing_id, store);
    blocked: dict[str, bool] = {};
    for e in ex {
        blocked[e] = True;
    }
    kept: list[str] = [];
    for cid in candidates {
        if cid in blocked {
            continue;
        }
        kept.append(cid);
    }
    return sorted(kept);
}

def would_create_cycle(editing_id: str, new_parent_id: str, store: dict[str, Doc]) -> bool {
    blocked = build_excluded_ids(editing_id, store);
    for e in blocked {
        if e == new_parent_id {
            return True;
        }
    }
    return False;
}

test "issue_chain_excludes_all_descendants" {
    store: dict[str, Doc] = {};
    cat2 = make_doc("391", "cat 2");
    register_doc(store, cat2);
    root ++> cat2;
    cat1 = make_doc("390", "cat 1");
    register_doc(store, cat1);
    connect_parent(cat2, cat1);
    cat4 = make_doc("393", "cat 4");
    register_doc(store, cat4);
    connect_parent(cat1, cat4);
    cat5 = make_doc("394", "cat 5");
    register_doc(store, cat5);
    connect_parent(cat4, cat5);
    pool: list[str] = ["391", "390", "393", "394", "999"];
    got = filter_parent_candidates("391", pool, store);
    assert got == ["999"];
    assert collect_descendant_ids("391", store) == ["390", "393", "394"];
}

test "diamond_revisit_skips_before_deeper_first_visits" {
    store: dict[str, Doc] = {};
    d = make_doc("D", "root");
    register_doc(store, d);
    root ++> d;
    a = make_doc("A", "left");
    register_doc(store, a);
    connect_parent(d, a);
    b = make_doc("B", "right");
    register_doc(store, b);
    connect_parent(d, b);
    c = make_doc("C", "join");
    register_doc(store, c);
    connect_parent(a, c);
    e = make_doc("E", "deep");
    register_doc(store, e);
    connect_parent(c, e);
    connect_parent(b, c);
    got = collect_descendant_ids("D", store);
    assert got == ["A", "B", "C", "E"];
}

test "unknown_editing_id_tolerates_missing_store_entry" {
    store: dict[str, Doc] = {};
    lone = make_doc("1", "only");
    register_doc(store, lone);
    root ++> lone;
    assert collect_descendant_ids("missing", store) == [];
    assert build_excluded_ids("missing", store) == ["missing"];
    assert filter_parent_candidates("missing", ["missing", "1", "9"], store) == ["1", "9"];
}

test "broken_breadcrumb_not_in_matches_issue_semantics" {
    self_only: list[str] = ["391"];
    assert broken_breadcrumb_not_in_match("391", self_only) == False;
    mixed: list[str] = ["391", "390", "393", "394"];
    assert broken_breadcrumb_not_in_match("391", mixed) == True;
}

test "would_create_cycle_flags_descendant_parent_pick" {
    store: dict[str, Doc] = {};
    cat2 = make_doc("391", "cat 2");
    register_doc(store, cat2);
    root ++> cat2;
    cat1 = make_doc("390", "cat 1");
    register_doc(store, cat1);
    connect_parent(cat2, cat1);
    cat5 = make_doc("394", "cat 5");
    register_doc(store, cat5);
    connect_parent(cat1, cat5);
    assert would_create_cycle("391", "394", store) == True;
    assert would_create_cycle("391", "999", store) == False;
}
