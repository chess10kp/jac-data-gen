"""wardle/hades#26 — Terminology graph with cross-system translation edges."""

node Concept {
    has cid: str;
}

edge HasParent {}

edge TranslatesTo {}

obj TermStore {
    has concepts: dict[str, Concept] = {};
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with Concept entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.anchor { self.found.append(here.cid); }
        visit [->:HasParent:->][?:Concept];
    }
}

walker TranslationWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with Concept entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.anchor { self.found.append(here.cid); }
        visit [->:TranslatesTo:->][?:Concept];
    }
}

def load_terminology(
    concept_ids: list[str],
    parent_edges: list[tuple[str, str]],
    translation_edges: list[tuple[str, str]],
) -> TermStore {
    store = TermStore();
    for cid in concept_ids {
        nd = Concept(cid=cid);
        root ++> nd;
        store.concepts[cid] = nd;
    }
    for (parent, child) in parent_edges {
        p = store.concepts.get(parent, None);
        c = store.concepts.get(child, None);
        if p is not None and c is not None { c +>:HasParent:+> p; }
    }
    for (src, dst) in translation_edges {
        s = store.concepts.get(src, None);
        d = store.concepts.get(dst, None);
        if s is not None and d is not None { s +>:TranslatesTo:+> d; }
    }
    return store;
}

def ancestors_of(store: TermStore, concept: str) -> list[str] {
    nd = store.concepts.get(concept, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk(claimed={}, anchor=concept);
    return sorted(w.found);
}

def translations_of(store: TermStore, concept: str) -> list[str] {
    nd = store.concepts.get(concept, None);
    if nd is None { return []; }
    w = nd spawn TranslationWalk(claimed={}, anchor=concept);
    return sorted(w.found);
}

def lookup_path(store: TermStore, concept: str, target_system: str) -> list[str] {
    nd = store.concepts.get(concept, None);
    if nd is None { return []; }
    for tgt in translations_of(store, concept) {
        if tgt.startswith(target_system) { return [concept, tgt]; }
    }
    return [];
}

test "terminology translations" {
    g = load_terminology(
        ["snomed:247", "snomed:parent", "icd:E11", "loinc:123"],
        [("snomed:parent", "snomed:247")],
        [("snomed:247", "icd:E11")],
    );
    assert lookup_path(g, "snomed:247", "icd:") == ["snomed:247", "icd:E11"];
}
