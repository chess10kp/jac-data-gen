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
