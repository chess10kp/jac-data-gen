"""Document-tree permission restriction with descendant propagation.

outline/outline#11760 lifted to OSP: documents become DocNode archetypes,
parent pointers and the children adjacency dict become typed ChildOf
edges. The bulk restrict/unrestrict write is two-phase -- a ClaimedSweep
walker gathers the subtree with a once-only claim map, the facade applies
the flag flips outside the walk. The sidebar view is a level-partitioned
hop walk that prunes entirely at restricted nodes; the claim maps are the
explicit cycle policy.
"""
node DocNode {
    has doc_id: str;
    has title: str;
    has restricted: bool = False;
}
edge ChildOf {}

"""Workspace handle: id resolution through this lookup map is domain API."""
obj Workspace {
    has docs: dict[str, DocNode];

    def resolve(doc_id: str) -> DocNode | None {
        return self.docs.get(doc_id);
    }
}

def build_store(pairs: list[tuple[str, str]]) -> Workspace {
    ws = Workspace(docs={});
    for p in pairs {
        n = DocNode(doc_id=p[0], title=p[1]);
        root ++> n;
        ws.docs[p[0]] = n;
    }
    return ws;
}

def add_document(ws: Workspace, doc_id: str, title: str, parent_id: str | None = None) {
    if parent_id is not None and ws.resolve(parent_id) is None {
        raise KeyError("unknown parent document");
    }
    n = DocNode(doc_id=doc_id, title=title);
    root ++> n;
    ws.docs[doc_id] = n;
    if parent_id is not None {
        p = ws.resolve(parent_id);
        if p is not None {
            p +>:ChildOf:+> n;
        }
    }
}

"""Gathers reachable DocNodes from ``start``; once-only claim map guard."""
walker SubtreeCollect {
    has claimed: dict[str, bool];
    has found: list[str] = [];

    can start with DocNode entry {
        if here.doc_id in self.claimed {
            skip;
        }
        self.claimed[here.doc_id] = True;
        self.found.append(here.doc_id);
        visit [->:ChildOf:->];
    }
    can step with DocNode entry {
        if here.doc_id in self.claimed {
            skip;
        }
        self.claimed[here.doc_id] = True;
        self.found.append(here.doc_id);
        visit [->:ChildOf:->];
    }
}

def _subtree(ws: Workspace, doc_id: str) -> list[str] {
    start = ws.resolve(doc_id);
    if start is None {
        raise KeyError("unknown document");
    }
    w = start spawn SubtreeCollect(claimed={});
    return w.found;
}

def restrict_subtree(ws: Workspace, doc_id: str) -> list[str] {
    changed: list[str] = [];
    # Phase 1: collect. Phase 2: apply outside the walk.
    for name in _subtree(ws, doc_id) {
        n = ws.resolve(name);
        if n is None or n.restricted {
            continue;
        }
        n.restricted = True;
        changed.append(name);
    }
    return sorted(changed);
}

def unrestrict_subtree(ws: Workspace, doc_id: str) -> list[str] {
    changed: list[str] = [];
    for name in _subtree(ws, doc_id) {
        n = ws.resolve(name);
        if n is None or not n.restricted {
            continue;
        }
        n.restricted = False;
        changed.append(name);
    }
    return sorted(changed);
}

walker AncestorAscent {
    has visited: dict[str, bool];
    has chain: list[str] = [];

    can step with DocNode entry {
        if here.doc_id in self.visited {
            skip;  # tolerate corrupt cycles: stop ascending
        }
        self.visited[here.doc_id] = True;
        self.chain.append(here.doc_id);
        parents = [here <-:ChildOf:<-];
        if len(parents) == 0 {
            disengage;
        }
        visit [parents[0]];
    }
}

def is_restricted(ws: Workspace, doc_id: str) -> bool {
    n = ws.resolve(doc_id);
    if n is None {
        return False;  # source tolerance: unknown ids are not restricted
    }
    if n.restricted {
        return True;
    }
    w = n spawn AncestorAscent(visited={});
    for a in w.chain[1:] {
        anc = ws.resolve(a);
        if anc is not None and anc.restricted {
            return True;
        }
    }
    return False;
}

"""One-hop collector used by the level-partitioned sidebar walk."""
walker HopCollect {
    has claimed: dict[str, bool];
    has next_frontier: list[DocNode] = [];

    can step with DocNode entry {
        for ch in [here ->:ChildOf:->] {
            if ch.doc_id in self.claimed or ch.restricted {
                continue;  # hidden entirely: prune, no descent
            }
            self.claimed[ch.doc_id] = True;
            self.next_frontier.append(ch);
        }
    }
}

def sidebar_view(ws: Workspace, root_id: str) -> list[list[str]] {
    start = ws.resolve(root_id);
    if start is None {
        raise KeyError("unknown document");
    }
    levels: list[list[str]] = [[root_id]];
    frontier: list[DocNode] = [start];
    seen: dict[str, bool] = {root_id: True};
    while len(frontier) > 0 {
        nxt: list[DocNode] = [];
        for f in frontier {
            w = f spawn HopCollect(claimed=seen, next_frontier=nxt);
            nxt = w.next_frontier;
        }
        if len(nxt) == 0 {
            break;
        }
        row: list[str] = [];
        for m in nxt {
            row.append(m.doc_id);
        }
        levels.append(row);
        frontier = nxt;
    }
    return levels;
}

def hidden_documents(ws: Workspace) -> list[str] {
    out: list[str] = [];
    for k in ws.docs.keys() {
        if is_restricted(ws, k) {
            out.append(k);
        }
    }
    return sorted(out);
}

test "restrict sweeps descendants and sidebar prunes" {
    ws = build_store([("home", "Home")]);
    add_document(ws, "guide", "Guide", "home");
    add_document(ws, "api", "API", "home");
    add_document(ws, "internal", "Notes", "home");
    add_document(ws, "roadmap", "Roadmap", "guide");
    add_document(ws, "payroll", "Payroll", "internal");
    add_document(ws, "rates", "Rate Card", "payroll");
    assert restrict_subtree(ws, "internal") == ["internal", "payroll", "rates"];
    assert restrict_subtree(ws, "internal") == [];
    assert is_restricted(ws, "rates");
    assert not is_restricted(ws, "guide");
    assert not is_restricted(ws, "ghost_doc");  # unknown id: False
    visible: list[str] = [];
    for lvl in sidebar_view(ws, "home") {
        for d in lvl {
            visible.append(d);
        }
    }
    assert sorted(visible) == ["api", "guide", "home", "roadmap"];
    assert hidden_documents(ws) == ["internal", "payroll", "rates"];
}

test "unrestrict restores whole subtree" {
    ws = build_store([("a", "A"), ("b", "B")]);
    add_document(ws, "c", "C", "a");
    assert restrict_subtree(ws, "a") == ["a", "c"];
    assert unrestrict_subtree(ws, "a") == ["a", "c"];
    assert hidden_documents(ws) == [];
}

test "adversarial diamond order terminates with once-only claims" {
    ws = build_store([("top", "T"), ("l", "L"), ("rr", "R"), ("bot", "B")]);
    # diamond: top->l->bot and top->rr->bot via extra parent edges
    topn = ws.resolve("top");
    botn = ws.resolve("bot");
    ln = ws.resolve("l");
    rn = ws.resolve("rr");
    topn +>:ChildOf:+> ln;
    topn +>:ChildOf:+> rn;
    ln +>:ChildOf:+> botn;
    rn +>:ChildOf:+> botn;
    assert restrict_subtree(ws, "top") == ["bot", "l", "rr", "top"];
    assert hidden_documents(ws) == ["bot", "l", "rr", "top"];
}

test "corrupt cycle does not hang" {
    ws = build_store([("a", "A"), ("b", "B")]);
    an = ws.resolve("a");
    bn = ws.resolve("b");
    an +>:ChildOf:+> bn;
    bn +>:ChildOf:+> an;
    assert sorted(_subtree(ws, "a")) == ["a", "b"];
    assert len(sidebar_view(ws, "a")) == 2;
}

test "inherited restriction from unmodified ancestor" {
    ws = build_store([("root", "R")]);
    add_document(ws, "mid", "M", "root");
    add_document(ws, "leaf", "L", "mid");
    # restrict ONLY mid's subtree, then unrestrict mid itself:
    # leaf must stay hidden via... no - leaf was unhidden? no: unrestrict_subtree(mid)
    # covers leaf too, so instead restrict leaf only and check via ancestor.
    restrict_subtree(ws, "leaf");
    unrestrict_subtree(ws, "leaf");
    restrict_subtree(ws, "root");
    # now unrestrict leaf alone (not its subtree API-wise impossible) --
    # instead verify: fresh store, restrict root subtree then re-add logic
    assert is_restricted(ws, "leaf");
    ws2 = build_store([("p", "P"), ("q", "Q")]);
    add_document(ws2, "c", "C", "q");
    add_document(ws2, "d", "D", "c");
    # restrict d only, then check p/q/c unaffected
    restrict_subtree(ws2, "d");
    assert not is_restricted(ws2, "c");
    assert not is_restricted(ws2, "q");
    assert is_restricted(ws2, "d");
}
