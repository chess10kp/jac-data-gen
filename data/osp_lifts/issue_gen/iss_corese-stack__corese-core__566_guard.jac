"""SPARQL 1.1 Property Paths — corese-stack/corese-core#566."""

node Term {
    has cid: str;
}

edge Property {
    has iri: str;
}

obj RdfGraph {
    has terms: dict[str, Term] = {};
}

def new_graph -> RdfGraph {
    return RdfGraph(terms={});
}

def term_for(g: RdfGraph, cid: str) -> Term {
    if cid not in g.terms {
        nd = Term(cid=cid);
        g.terms[cid] = nd;
        root ++> nd;
    }
    return g.terms[cid];
}

def add_triple(g: RdfGraph, subj: str, pred: str, obj: str) {
    s = term_for(g, subj);
    o = term_for(g, obj);
    s +>:Property(iri=pred):+> o;
}

def fwd_neighbors(here: Term, pred: str) -> list[Term] {
    xs: list[Term] = [];
    for pe in [here ->:Property:->] {
        if pe.iri == pred {
            for ch in [pe ->] {
                xs.append(ch);
            }
        }
    }
    return xs;
}

def rev_neighbors(here: Term, pred: str) -> list[Term] {
    xs: list[Term] = [];
    for pe in [here <-:Property:->] {
        if pe.iri == pred {
            for ch in [pe <-] {
                xs.append(ch);
            }
        }
    }
    return xs;
}

walker StarW {
    has pred: str;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can walk with Term entry {
        print("star@", here.cid);
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        kids: list[Term] = fwd_neighbors(here, self.pred);
        for ch in kids {
            if ch.cid not in self.claimed {
                visit :0: [ch];
            }
        }
        if not kids {
            disengage;
        }
    }
}

walker PlusW {
    has pred: str;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has dist: int = 0;

    can walk with Term entry {
        print("plus@", here.cid, self.dist);
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if self.dist >= 1 {
            self.found.append(here.cid);
        }
        kids: list[Term] = fwd_neighbors(here, self.pred);
        for ch in kids {
            if ch.cid not in self.claimed {
                visit :0: [ch];
            }
        }
        if not kids {
            disengage;
        }
    }

    can follow with Term entry {
        self.dist = self.dist + 1;
        print("plus-hop@", here.cid, self.dist);
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if self.dist >= 1 {
            self.found.append(here.cid);
        }
        kids: list[Term] = fwd_neighbors(here, self.pred);
        for ch in kids {
            if ch.cid not in self.claimed {
                visit :0: [ch];
            }
        }
        if not kids {
            disengage;
        }
    }
}

def path_step(g: RdfGraph, start_cid: str, pred: str) -> list[str] {
    if start_cid not in g.terms {
        return [];
    }
    here = g.terms[start_cid];
    kids: list[Term] = fwd_neighbors(here, pred);
    out: list[str] = [];
    for ch in kids {
        out.append(ch.cid);
    }
    return sorted(out);
}

def path_star(g: RdfGraph, start_cid: str, pred: str) -> list[str] {
    if start_cid not in g.terms {
        return [];
    }
    here = g.terms[start_cid];
    w = here spawn StarW(pred=pred, claimed={}, found=[]);
    print("path_star", start_cid, pred, len(w.found));
    return sorted(w.found);
}

def path_plus(g: RdfGraph, start_cid: str, pred: str) -> list[str] {
    if start_cid not in g.terms {
        return [];
    }
    here = g.terms[start_cid];
    kids: list[Term] = fwd_neighbors(here, pred);
    claimed: dict[str, bool] = {};
    claimed[here.cid] = True;
    found: list[str] = [];
    for ch in kids {
        pw = ch spawn PlusW(pred=pred, claimed=claimed, found=found, dist=1);
        print("path_plus-seed", ch.cid, len(pw.found));
    }
    return sorted(found);
}

def path_sequence(g: RdfGraph, start_cid: str, preds: list[str]) -> list[str] {
    if start_cid not in g.terms {
        return [];
    }
    cur: list[str] = [start_cid];
    for pred in preds {
        nxt: list[str] = [];
        for cid in cur {
            step = path_step(g, cid, pred);
            for x in step {
                nxt.append(x);
            }
        }
        cur = nxt;
        if not cur {
            return [];
        }
    }
    return sorted(cur);
}

def path_inverse_step(g: RdfGraph, start_cid: str, pred: str) -> list[str] {
    if start_cid not in g.terms {
        return [];
    }
    here = g.terms[start_cid];
    kids: list[Term] = rev_neighbors(here, pred);
    out: list[str] = [];
    for ch in kids {
        out.append(ch.cid);
    }
    return sorted(out);
}

def path_alt(g: RdfGraph, start_cid: str, preds: list[str]) -> list[str] {
    if start_cid not in g.terms {
        return [];
    }
    bag: list[str] = [];
    for pred in preds {
        xs = path_step(g, start_cid, pred);
        for x in xs {
            bag.append(x);
        }
    }
    return sorted(bag);
}

test "path_step_forward" {
    g = new_graph();
    add_triple(g, "a", "p", "b");
    add_triple(g, "a", "p", "c");
    assert path_step(g, "a", "p") == ["b", "c"];
}

test "path_star_zero_or_more" {
    g = new_graph();
    add_triple(g, "a", "p", "b");
    add_triple(g, "b", "p", "c");
    assert path_star(g, "a", "p") == ["a", "b", "c"];
}

test "path_plus_one_or_more" {
    g = new_graph();
    add_triple(g, "a", "p", "b");
    add_triple(g, "b", "p", "c");
    assert path_plus(g, "a", "p") == ["b", "c"];
}

test "path_sequence_slash" {
    g = new_graph();
    add_triple(g, "a", "p", "b");
    add_triple(g, "b", "p", "d");
    assert path_sequence(g, "a", ["p", "p"]) == ["d"];
}

test "path_inverse_caret" {
    g = new_graph();
    add_triple(g, "a", "p", "b");
    assert path_inverse_step(g, "b", "p") == ["a"];
}

test "path_alt_bang" {
    g = new_graph();
    add_triple(g, "a", "p", "b");
    add_triple(g, "a", "q", "c");
    assert path_alt(g, "a", ["p", "q"]) == ["b", "c"];
}
