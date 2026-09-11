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
