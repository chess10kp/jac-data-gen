"""seandavi/taxonset-db#8 — taxonomy subtree queries (OSP lift)."""

obj TaxonStore { has taxa: dict[str, Taxon] = {}; }

node Taxon {
    has tid: str;
    has rank: str;
}

edge ParentOf {}

def load_taxonomy(
    taxa: list[tuple[str, str]],
    parent_edges: list[tuple[str, str]],
) -> TaxonStore {
    store = TaxonStore();
    for (tid, rank) in taxa {
        if tid not in store.taxa {
            t = Taxon(tid=tid, rank=rank);
            root ++> t;
            store.taxa[tid] = t;
        }
    }
    for (parent, child) in parent_edges {
        p = store.taxa.get(parent, None);
        c = store.taxa.get(child, None);
        if p is not None and c is not None { p +>:ParentOf:+> c; }
    }
    return store;
}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Taxon entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.reached.append(here.tid);
        for ch in [here ->:ParentOf:->][?:Taxon] {
            visit [ch];
        }
    }
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with Taxon entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.chain.append(here.tid);
        parents = [here <-:ParentOf:<-][?:Taxon];
        if not parents { disengage; }
        pick = parents[0];
        for p in parents {
            if p.tid < pick.tid { pick = p; }
        }
        visit [pick];
    }
}

def descendants(store: TaxonStore, tax_id: str) -> list[str] {
    anchor = store.taxa.get(tax_id, None);
    if anchor is None { return []; }
    w = anchor spawn DescendantWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def ancestor_chain(store: TaxonStore, tax_id: str) -> list[str] {
    anchor = store.taxa.get(tax_id, None);
    if anchor is None { return []; }
    w = anchor spawn AncestorWalk(claimed={}, chain=[]);
    return w.chain;
}

def taxa_by_rank(store: TaxonStore, root_id: str, rank: str) -> list[str] {
    return sorted([t for t in descendants(store, root_id) if store.taxa[t].rank == rank]);
}
