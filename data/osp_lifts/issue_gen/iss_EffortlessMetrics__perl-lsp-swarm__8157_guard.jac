"""EffortlessMetrics/perl-lsp-swarm#8157 — recursive document-symbol projection."""

glob KIND_RANK: dict[str, int] = {
    "package": 0,
    "class": 1,
    "role": 2,
    "method": 3,
    "sub": 4,
    "field": 5,
    "constant": 6,
    "variable": 7,
    "lexical": 99,
};

node Decl {
    has did: str;
    has name: str = "";
    has kind: str = "";
    has provenance: str = "";
    has start: int = 0;
    has end: int = 0;
}

edge HasChild: Decl --> Decl {}

edge BodyMember: Decl --> Decl {}

edge ReachEdge: Decl --> Decl {}

obj DeclarationGraph {
    has _decls: set[str] = set();
    has _parent: dict[str, str | None] = {};
    has _children: dict[str, list[str]] = {};
    has _body_members: dict[str, list[str]] = {};
    has _reach: dict[str, list[str]] = {};
    has _meta: dict[str, dict] = {};
}

def _decl_node(did: str) -> Decl | None {
    for nd in [root -->][?:Decl] {
        if nd.did == did { return nd; }
    }
    return None;
}

walker ProjectSubtreeWalk {
    has gref: DeclarationGraph;
    has claimed: dict[str, bool] = {};
    has forest: list[dict] = [];

    can build with Decl entry {
        if here.did in self.claimed { skip; }
        if not outline_visible(here.kind, here.provenance) {
            for mid in _member_ids(self.gref, here.did) {
                mnd = _decl_node(mid);
                if mnd is not None {
                    sub = mnd spawn ProjectSubtreeWalk(
                        gref=self.gref, claimed=self.claimed, forest=[]
                    );
                    for item in sub.forest { self.forest.append(item); }
                }
            }
            skip;
        }
        self.claimed[here.did] = True;
        children: list[dict] = [];
        for mid in _member_ids(self.gref, here.did) {
            mnd = _decl_node(mid);
            if mnd is not None {
                sub = mnd spawn ProjectSubtreeWalk(
                    gref=self.gref, claimed=self.claimed, forest=[]
                );
                for item in sub.forest { children.append(item); }
            }
        }
        sym = {
            "id": here.did,
            "name": here.name,
            "kind": here.kind,
            "children": children,
        };
        self.forest = [sym];
    }
}

walker VisibleDescendantsWalk {
    has gref: DeclarationGraph;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Decl entry {
        if here.did in self.claimed { skip; }
        self.claimed[here.did] = True;
        if here.did != self.origin and outline_visible(here.kind, here.provenance) {
            self.found.append(here.did);
        }
        for did in _member_ids(self.gref, here.did) {
            if did not in self.claimed {
                mnd = _decl_node(did);
                if mnd is not None { visit mnd; }
            }
        }
    }
}

walker DeclarationReachWalk {
    has gref: DeclarationGraph;
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has origin: str = "";

    can step with Decl entry {
        if here.did in self.claimed { skip; }
        self.claimed[here.did] = True;
        if here.did != self.origin { self.order.append(here.did); }
        nbrs: list[Decl] = [];
        for c in [here ->:HasChild:->][?:Decl] { nbrs.append(c); }
        for r in [here ->:ReachEdge:->][?:Decl] { nbrs.append(r); }
        ids: list[str] = [];
        for n in nbrs { ids.append(n.did); }
        for did in _sorted_ids(self.gref, ids) {
            for n in nbrs {
                if n.did == did and n.did not in self.claimed { visit n; }
            }
        }
    }
}

def load_declaration_graph(
    declarations: list[str],
    parent_of: list[tuple[str, str | None]],
    body_members: list[tuple[str, str]],
    meta: dict[str, dict],
    reach_edges: list[tuple[str, str]] | None = None,
) -> DeclarationGraph {
    g = DeclarationGraph();
    for did in declarations {
        g._decls.add(did);
        g._parent.setdefault(did, None);
        g._children.setdefault(did, []);
        g._body_members.setdefault(did, []);
        g._reach.setdefault(did, []);
        if _decl_node(did) is None {
            root ++> Decl(did=did);
        }
    }
    for (child, parent) in parent_of {
        if child in g._decls {
            if parent is None or parent in g._decls {
                g._parent[child] = parent;
                if parent is not None {
                    g._children[parent].append(child);
                    pnd = _decl_node(parent);
                    cnd = _decl_node(child);
                    if pnd is not None and cnd is not None { pnd +>:HasChild:+> cnd; }
                }
            } else {
                g._parent[child] = None;
            }
        }
    }
    for (owner, member) in body_members {
        if owner in g._decls and member in g._decls {
            g._body_members[owner].append(member);
            ow = _decl_node(owner);
            mb = _decl_node(member);
            if ow is not None and mb is not None { ow +>:BodyMember:+> mb; }
        }
    }
    for (did, row) in meta.items() {
        if did in g._decls {
            g._meta[did] = dict(row);
            maybe = _decl_node(did);
            if maybe is not None {
                maybe.name = row.get("name", "");
                maybe.kind = row.get("kind", "");
                maybe.provenance = row.get("provenance", "");
                maybe.start = row.get("start", 0);
                maybe.end = row.get("end", 0);
            }
        }
    }
    for (src, dst) in reach_edges or [] {
        if src in g._decls and dst in g._decls {
            reach = g._reach[src];
            if dst not in reach {
                reach.append(dst);
                snd = _decl_node(src);
                dnd = _decl_node(dst);
                if snd is not None and dnd is not None { snd +>:ReachEdge:+> dnd; }
            }
        }
    }
    return g;
}

def outline_visible(kind: str, provenance: str) -> bool {
    if provenance != "source-backed" { return False; }
    return kind not in ("lexical", "block", "anon");
}

def source_sort_key(g: DeclarationGraph, decl_id: str) -> tuple {
    row = g._meta[decl_id];
    return (
        row["start"],
        row["end"],
        KIND_RANK.get(row["kind"], 50),
        decl_id,
    );
}

def _sorted_ids(g: DeclarationGraph, ids: list[str]) -> list[str] {
    pairs: list[tuple] = [];
    for did in ids { pairs.append((source_sort_key(g, did), did)); }
    pairs.sort();
    out: list[str] = [];
    for pr in pairs { out.append(pr[1]); }
    return out;
}

def _member_ids(g: DeclarationGraph, container_id: str) -> list[str] {
    body = g._body_members.get(container_id, []);
    if body { return _sorted_ids(g, body); }
    direct: list[str] = [];
    for c in g._children.get(container_id, []) {
        if g._parent.get(c, None) == container_id { direct.append(c); }
    }
    return _sorted_ids(g, direct);
}

def _project_decl(
    g: DeclarationGraph, decl_id: str, claimed: dict[str, bool]
) -> list[dict] {
    if decl_id in claimed { return []; }
    if decl_id not in g._decls { return []; }
    nd = _decl_node(decl_id);
    if nd is None { return []; }
    w = nd spawn ProjectSubtreeWalk(gref=g, claimed=claimed, forest=[]);
    out: list[dict] = [];
    for x in w.forest { out.append(x); }
    return out;
}

def project_document_symbols(g: DeclarationGraph) -> list[dict] {
    roots: list[str] = [];
    for did in g._decls {
        if g._parent.get(did, None) is None { roots.append(did); }
    }
    claimed: dict[str, bool] = {};
    forest: list[dict] = [];
    for root_id in _sorted_ids(g, roots) {
        for sym in _project_decl(g, root_id, claimed) { forest.append(sym); }
    }
    return forest;
}

def flatten_identities(forest: list[dict]) -> list[str] {
    out: list[str] = [];
    stack: list[dict] = [];
    for i in range(len(forest) - 1, -1, -1) { stack.append(forest[i]); }
    while stack {
        sym = stack.pop();
        out.append(sym["id"]);
        kids: list = sym.get("children", []);
        for j in range(len(kids) - 1, -1, -1) {
            ch: dict = kids[j];
            stack.append(ch);
        }
    }
    return out;
}

def visible_descendants(g: DeclarationGraph, anchor_id: str) -> list[str] {
    if anchor_id not in g._decls { return []; }
    nd = _decl_node(anchor_id);
    if nd is None { return []; }
    w = nd spawn VisibleDescendantsWalk(
        gref=g, claimed={}, found=[], origin=anchor_id
    );
    return _sorted_ids(g, w.found);
}

def declaration_reach(g: DeclarationGraph, start_id: str) -> list[str] {
    if start_id not in g._decls { return []; }
    nd = _decl_node(start_id);
    if nd is None { return []; }
    w = nd spawn DeclarationReachWalk(
        gref=g, claimed={}, order=[], origin=start_id
    );
    return w.order;
}

test "body_members projection and visible_descendants from method anchor" {
    g = load_declaration_graph(
        ["helper", "pkg", "lex", "meth", "const", "fld", "cls"],
        [
            ("pkg", None),
            ("cls", "pkg"),
            ("fld", "cls"),
            ("meth", "cls"),
            ("lex", "meth"),
            ("const", "lex"),
            ("helper", "meth"),
        ],
        [("meth", "lex"), ("meth", "const"), ("meth", "helper")],
        {
            "pkg": {"name": "Main", "kind": "package", "provenance": "source-backed", "start": 0, "end": 200},
            "cls": {"name": "App", "kind": "class", "provenance": "source-backed", "start": 10, "end": 190},
            "fld": {"name": "size", "kind": "field", "provenance": "source-backed", "start": 12, "end": 13},
            "meth": {"name": "run", "kind": "method", "provenance": "source-backed", "start": 30, "end": 150},
            "lex": {"name": "_lex", "kind": "lexical", "provenance": "source-backed", "start": 32, "end": 140},
            "const": {"name": "C", "kind": "constant", "provenance": "source-backed", "start": 35, "end": 40},
            "helper": {"name": "helper", "kind": "sub", "provenance": "source-backed", "start": 50, "end": 100},
        },
    );
    forest = project_document_symbols(g);
    assert flatten_identities(forest) == ["pkg", "cls", "fld", "meth", "const", "helper"];;
    assert visible_descendants(g, "meth") == ["const", "helper"];;
    assert visible_descendants(g, "missing") == [];;
}

test "declaration_reach diamond revisit via shared reach target" {
    g = load_declaration_graph(
        ["hub", "left", "right", "sink"],
        [("left", "hub"), ("right", "hub")],
        [],
        {
            "hub": {"name": "Hub", "kind": "package", "provenance": "source-backed", "start": 0, "end": 100},
            "left": {"name": "left", "kind": "method", "provenance": "source-backed", "start": 10, "end": 20},
            "right": {"name": "right", "kind": "method", "provenance": "source-backed", "start": 20, "end": 30},
            "sink": {"name": "sink", "kind": "sub", "provenance": "source-backed", "start": 30, "end": 40},
        },
        [("left", "sink"), ("right", "sink")],
    );
    assert declaration_reach(g, "hub") == ["left", "right", "sink"];;
    assert declaration_reach(g, "sink") == [];;
}

test "unknown id tolerance across loaders and queries" {
    g = load_declaration_graph(
        ["pkg"],
        [("ghost_child", "pkg"), ("pkg", "ghost_parent")],
        [("pkg", "missing_member")],
        {
            "pkg": {"name": "Pkg", "kind": "package", "provenance": "source-backed", "start": 0, "end": 50},
            "orphan_meta": {"name": "X", "kind": "sub", "provenance": "source-backed", "start": 1, "end": 2},
        },
        [("pkg", "nowhere"), ("phantom", "pkg")],
    );
    assert declaration_reach(g, "nope") == [];;
    assert visible_descendants(g, "nope") == [];;
    assert declaration_reach(g, "pkg") == [];;
    assert visible_descendants(g, "pkg") == [];;
    assert flatten_identities(project_document_symbols(g)) == ["pkg"];;
}

test "invisible lexical hoists visible method to package" {
    g = load_declaration_graph(
        ["pkg", "lex", "meth"],
        [("lex", "pkg"), ("meth", "lex")],
        [],
        {
            "pkg": {"name": "Main", "kind": "package", "provenance": "source-backed", "start": 0, "end": 200},
            "lex": {"name": "myblock", "kind": "lexical", "provenance": "source-backed", "start": 10, "end": 180},
            "meth": {"name": "run", "kind": "method", "provenance": "source-backed", "start": 20, "end": 40},
        },
    );
    forest = project_document_symbols(g);
    assert len(forest) == 1;;
    assert forest[0]["id"] == "pkg";;
    assert len(forest[0]["children"]) == 1;;
    assert forest[0]["children"][0]["id"] == "meth";;
    assert flatten_identities(forest) == ["pkg", "meth"];;
}

test "body_members overrides direct children for projection" {
    g = load_declaration_graph(
        ["pkg", "direct", "body"],
        [("direct", "pkg"), ("body", "pkg")],
        [("pkg", "body")],
        {
            "pkg": {"name": "Pkg", "kind": "package", "provenance": "source-backed", "start": 0, "end": 100},
            "direct": {"name": "direct_sub", "kind": "sub", "provenance": "source-backed", "start": 10, "end": 20},
            "body": {"name": "body_sub", "kind": "sub", "provenance": "source-backed", "start": 30, "end": 40},
        },
    );
    forest = project_document_symbols(g);
    assert flatten_identities(forest) == ["pkg", "body"];;
    assert "direct" not in flatten_identities(forest);;
}

test "visible_descendants traverses invisible skips inferred" {
    g = load_declaration_graph(
        ["pkg", "lex", "meth", "guess"],
        [("lex", "pkg"), ("meth", "lex"), ("guess", "pkg")],
        [],
        {
            "pkg": {"name": "Pkg", "kind": "package", "provenance": "source-backed", "start": 0, "end": 200},
            "lex": {"name": "blk", "kind": "block", "provenance": "source-backed", "start": 10, "end": 150},
            "meth": {"name": "run", "kind": "method", "provenance": "source-backed", "start": 20, "end": 30},
            "guess": {"name": "maybe", "kind": "method", "provenance": "inferred", "start": 5, "end": 6},
        },
    );
    assert visible_descendants(g, "pkg") == ["meth"];;
    assert visible_descendants(g, "lex") == ["meth"];;
    assert visible_descendants(g, "guess") == [];;
}

test "declaration_reach cycle skips revisit without disengage" {
    g = load_declaration_graph(
        ["a", "b", "c"],
        [],
        [],
        {
            "a": {"name": "A", "kind": "package", "provenance": "source-backed", "start": 0, "end": 10},
            "b": {"name": "B", "kind": "method", "provenance": "source-backed", "start": 10, "end": 20},
            "c": {"name": "C", "kind": "method", "provenance": "source-backed", "start": 20, "end": 30},
        },
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert declaration_reach(g, "a") == ["b", "c"];;
    assert declaration_reach(g, "b") == ["c", "a"];;
    assert declaration_reach(g, "c") == ["a", "b"];;
}
