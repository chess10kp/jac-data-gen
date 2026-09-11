"""linkml/linkml-term-validator#58 — OAK reachable_from closure scope validation."""

node Term {
    has term_id: str;
}

edge IsA: Term --> Term;

edge PartOf: Term --> Term;

obj OntologyStore {
    has terms_by_id: dict[str, Term] = {};

    def add_term(term_id: str) -> Term {
        t = Term(term_id=term_id);
        root ++> t;
        self.terms_by_id[term_id] = t;
        return t;
    }

    def link_is_a(child_id: str, parent_id: str) {
        child = self.terms_by_id.get(child_id);
        parent = self.terms_by_id.get(parent_id);
        if child and parent {
            child +>:IsA:+> parent;
        }
    }

    def link_part_of(part_id: str, whole_id: str) {
        part = self.terms_by_id.get(part_id);
        whole = self.terms_by_id.get(whole_id);
        if part and whole {
            part +>:PartOf:+> whole;
        }
    }
}

walker descend_closure {
    has claims: dict[str, bool] = {},
        out: list[str] = [],
        include_part_of: bool = False,
        prefix_filter: str = "";

    can walk with Term entry {
        if here.term_id in self.claims {
            skip;
        }
        self.claims[here.term_id] = True;
        if self.prefix_filter == "" or here.term_id.startswith(self.prefix_filter) {
            self.out.append(here.term_id);
        }
        visit [<-:IsA:<-];
        if self.include_part_of {
            visit [<-:PartOf:<-];
        }
    }
}

walker ascend_closure {
    has claims: dict[str, bool] = {},
        out: list[str] = [],
        include_part_of: bool = False;

    can walk with Term entry {
        if here.term_id in self.claims {
            skip;
        }
        self.claims[here.term_id] = True;
        self.out.append(here.term_id);
        visit [->:IsA:->];
        if self.include_part_of {
            visit [->:PartOf:->];
        }
    }
}

def descendants(
    store: OntologyStore,
    term_id: str,
    include_part_of: bool = False,
    prefix_filter: str = "",
) -> list[str] {
    term = store.terms_by_id.get(term_id);
    if not term {
        return [];
    }
    w = term spawn descend_closure(
        include_part_of=include_part_of,
        prefix_filter=prefix_filter,
    );
    return sorted(w.out);
}

def ancestors(
    store: OntologyStore,
    term_id: str,
    include_part_of: bool = False,
) -> list[str] {
    term = store.terms_by_id.get(term_id);
    if not term {
        return [];
    }
    w = term spawn ascend_closure(include_part_of=include_part_of);
    return sorted(w.out);
}

test "diamond revisit yields one X" {
    s = OntologyStore();
    s.add_term("GO:ROOT");
    s.add_term("GO:A");
    s.add_term("GO:B");
    s.add_term("GO:X");
    s.link_is_a("GO:B", "GO:ROOT");
    s.link_is_a("GO:A", "GO:ROOT");
    s.link_is_a("GO:X", "GO:B");
    s.link_is_a("GO:X", "GO:A");
    got = descendants(s, "GO:ROOT");
    assert got == sorted(["GO:A", "GO:B", "GO:ROOT", "GO:X"]);
}

test "unknown term id returns empty" {
    s = OntologyStore();
    s.add_term("GO:ROOT");
    assert descendants(s, "MISSING:999") == [];
    assert ancestors(s, "MISSING:999") == [];
}

test "prefix filter scopes merged ubergraph-like closure" {
    s = OntologyStore();
    s.add_term("GO:0005575");
    s.add_term("GO:0005623");
    s.add_term("MRO:0000001");
    s.link_is_a("GO:0005623", "GO:0005575");
    s.link_is_a("MRO:0000001", "GO:0005575");
    all_ids = descendants(s, "GO:0005575");
    go_ids = descendants(s, "GO:0005575", prefix_filter="GO:");
    assert all_ids == sorted(["GO:0005575", "GO:0005623", "MRO:0000001"]);
    assert go_ids == sorted(["GO:0005575", "GO:0005623"]);
}

test "part_of edges extend descendant closure" {
    s = OntologyStore();
    s.add_term("GO:CC");
    s.add_term("GO:PART");
    s.link_part_of("GO:PART", "GO:CC");
    assert descendants(s, "GO:CC", include_part_of=False) == ["GO:CC"];
    assert descendants(s, "GO:CC", include_part_of=True) == sorted(["GO:CC", "GO:PART"]);
}

test "ancestors walk is_a chain" {
    s = OntologyStore();
    s.add_term("GO:1");
    s.add_term("GO:2");
    s.add_term("GO:3");
    s.link_is_a("GO:3", "GO:2");
    s.link_is_a("GO:2", "GO:1");
    assert ancestors(s, "GO:3") == sorted(["GO:1", "GO:2", "GO:3"]);
}
