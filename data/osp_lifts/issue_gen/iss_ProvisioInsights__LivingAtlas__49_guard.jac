"""ProvisioInsights/LivingAtlas#49 — typed Praxis knowledge APIs and canonical export/import."""

node KnowledgeEntity {
    has eid: str;
    has tombstone: bool = False;
    has fields: dict = {};
}

node KnowledgeFact {
    has entity_id: str;
    has fact_key: str;
    has valid_at: str = "";
    has fields: dict = {};
}

edge DependsOn: KnowledgeEntity --> KnowledgeEntity {}
edge ChildOf: KnowledgeEntity --> KnowledgeEntity {}
edge HasFact: KnowledgeEntity --> KnowledgeFact {}

def _resolve_entity(eid: str) -> KnowledgeEntity | None {
    for nd in [root -->][?:KnowledgeEntity] {
        if nd.eid == eid { return nd; }
    }
    return None;
}

def _fact_sort_key(row: dict) -> tuple {
    return (str(row["key"]), str(row.get("valid_at", "")));
}

def _entity_sort_key(ent: dict) -> str {
    return str(ent["id"]);
}

walker UpstreamDepWalk {
    has claimed: dict[str, bool] = {};
    has node_depth: dict[str, int] = {};
    has hits: list[str] = [];
    has max_hops: int = 8;
    has origin: str = "";

    can step with KnowledgeEntity entry {
        if here.eid in self.claimed { skip; }
        if not (here.eid in self.node_depth) {
            self.node_depth[here.eid] = 0;
        }
        depth = self.node_depth[here.eid];
        self.claimed[here.eid] = True;
        if here.eid != self.origin {
            self.hits.append(here.eid);
        }
        if depth >= self.max_hops { skip; }
        deps = [here ->:DependsOn:->][?:KnowledgeEntity];
        nms: list[str] = [];
        for d in deps { nms.append(d.eid); }
        for nm in sorted(nms) {
            for d in deps {
                if d.eid == nm {
                    if not (d.eid in self.node_depth) {
                        self.node_depth[d.eid] = depth + 1;
                    }
                    visit [d];
                }
            }
        }
    }
}

walker DownstreamDepWalk {
    has claimed: dict[str, bool] = {};
    has node_depth: dict[str, int] = {};
    has hits: list[str] = [];
    has max_hops: int = 8;
    has origin: str = "";

    can step with KnowledgeEntity entry {
        if here.eid in self.claimed { skip; }
        if not (here.eid in self.node_depth) {
            self.node_depth[here.eid] = 0;
        }
        depth = self.node_depth[here.eid];
        self.claimed[here.eid] = True;
        if here.eid != self.origin {
            self.hits.append(here.eid);
        }
        if depth >= self.max_hops { skip; }
        deps = [here <-:DependsOn:<-][?:KnowledgeEntity];
        nms: list[str] = [];
        for d in deps { nms.append(d.eid); }
        for nm in sorted(nms) {
            for d in deps {
                if d.eid == nm {
                    if not (d.eid in self.node_depth) {
                        self.node_depth[d.eid] = depth + 1;
                    }
                    visit [d];
                }
            }
        }
    }
}

walker DependsPathWalk {
    has target: str = "";
    has parent_of: dict[str, str] = {};
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    can step with KnowledgeEntity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if here.eid == self.target {
            self.found = True;
            disengage;
        }
        deps = [here ->:DependsOn:->][?:KnowledgeEntity];
        nms: list[str] = [];
        for d in deps { nms.append(d.eid); }
        for nm in sorted(nms) {
            for d in deps {
                if d.eid == nm and not (d.eid in self.parent_of) {
                    self.parent_of[d.eid] = here.eid;
                    visit [d];
                }
            }
        }
    }
}

def make_knowledge_graph(
    entities: list[dict],
    facts: list[dict],
    depends: list[tuple[str, str]],
    parents: list[tuple[str, str]],
) -> dict {
    entity_map: dict[str, dict] = {};
    for e in entities {
        eid = e["id"];
        entity_map[eid] = dict(e);
    }
    facts_map: dict[str, list[dict]] = {};
    for fact in facts {
        feid = fact["entity_id"];
        facts_map.setdefault(feid, []).append(dict(fact));
    }
    dep_fwd: dict[str, list[str]] = {};
    dep_rev: dict[str, list[str]] = {};
    for (dependent, dependency) in depends {
        dep_fwd.setdefault(dependent, []);
        if dependency not in dep_fwd[dependent] {
            dep_fwd[dependent].append(dependency);
        }
        dep_rev.setdefault(dependency, []);
        if dependent not in dep_rev[dependency] {
            dep_rev[dependency].append(dependent);
        }
    }
    parent_map: dict[str, str] = {};
    children_map: dict[str, list[str]] = {};
    for (child, parent) in parents {
        parent_map[child] = parent;
        children_map.setdefault(parent, []);
        if child not in children_map[parent] {
            children_map[parent].append(child);
        }
    }
    for e in entities {
        eid = e["id"];
        tomb = bool(e.get("tombstone", False));
        extra: dict = {};
        for (k, v) in e.items() {
            if k != "id" and k != "tombstone" {
                extra[k] = v;
            }
        }
        nd = KnowledgeEntity(eid=eid, tombstone=tomb, fields=extra);
        root ++> nd;
    }
    for fact in facts {
        feid = fact["entity_id"];
        ent = _resolve_entity(feid);
        if ent is None { continue; }
        fk = str(fact.get("key", ""));
        va = str(fact.get("valid_at", ""));
        fextra: dict = {};
        for (k, v) in fact.items() {
            if k != "entity_id" and k != "key" and k != "valid_at" {
                fextra[k] = v;
            }
        }
        fnd = KnowledgeFact(entity_id=feid, fact_key=fk, valid_at=va, fields=fextra);
        ent +>:HasFact:+> fnd;
    }
    for (dependent, dependency) in depends {
        a = _resolve_entity(dependent);
        b = _resolve_entity(dependency);
        if a is not None and b is not None {
            a +>:DependsOn:+> b;
        }
    }
    for (child, parent) in parents {
        c = _resolve_entity(child);
        p = _resolve_entity(parent);
        if c is not None and p is not None {
            c +>:ChildOf:+> p;
        }
    }
    return {
        "entities": entity_map,
        "facts": facts_map,
        "dep_fwd": dep_fwd,
        "dep_rev": dep_rev,
        "parent": parent_map,
        "children": children_map,
    };
}

def get_entity(graph: dict, entity_id: str) -> dict | None {
    ents = graph["entities"] as dict[str, dict];
    ent = ents.get(entity_id, None);
    if ent is None { return None; }
    return dict(ent);
}

def query_facts(graph: dict, entity_id: str) -> list[dict] {
    facts = graph["facts"] as dict[str, list[dict]];
    rows: list[dict] = facts.get(entity_id, []);
    sorted_rows = sorted(rows, key=_fact_sort_key);
    out: list[dict] = [];
    for row in sorted_rows { out.append(dict(row)); }
    return out;
}

def upstream_dependencies(graph: dict, entity_id: str, max_hops: int = 8) -> list[str] {
    ents = graph["entities"] as dict[str, dict];
    if entity_id not in ents { return []; }
    nd = _resolve_entity(entity_id);
    if nd is None { return []; }
    w = nd spawn UpstreamDepWalk(
        claimed={}, node_depth={}, hits=[], max_hops=max_hops, origin=entity_id
    );
    return sorted(w.hits);
}

def downstream_dependents(graph: dict, entity_id: str, max_hops: int = 8) -> list[str] {
    ents = graph["entities"] as dict[str, dict];
    if entity_id not in ents { return []; }
    nd = _resolve_entity(entity_id);
    if nd is None { return []; }
    w = nd spawn DownstreamDepWalk(
        claimed={}, node_depth={}, hits=[], max_hops=max_hops, origin=entity_id
    );
    return sorted(w.hits);
}

def depends_path(graph: dict, src: str, dst: str) -> list[str] {
    ents = graph["entities"] as dict[str, dict];
    if src not in ents or dst not in ents { return []; }
    nd = _resolve_entity(src);
    if nd is None { return []; }
    w = nd spawn DependsPathWalk(target=dst, parent_of={}, claimed={}, found=False);
    if not w.found { return []; }
    trail: list[str] = [];
    cur: str | None = dst;
    while cur is not None {
        trail.append(cur);
        if cur == src { break; }
        cur = w.parent_of.get(cur, None);
    }
    if len(trail) == 0 or trail[len(trail) - 1] != src { return []; }
    out: list[str] = [];
    for i in range(len(trail) - 1, -1, -1) { out.append(trail[i]); }
    return out;
}

def lineage_to_root(graph: dict, entity_id: str) -> list[str] {
    ents = graph["entities"] as dict[str, dict];
    if entity_id not in ents { return []; }
    chain: list[str] = [entity_id];
    claimed: dict[str, bool] = {entity_id: True};
    cur = _resolve_entity(entity_id);
    if cur is None { return chain; }
    while True {
        parents = [cur ->:ChildOf:->][?:KnowledgeEntity];
        if len(parents) == 0 { break; }
        pnames: list[str] = [];
        for p in parents { pnames.append(p.eid); }
        par_eid = sorted(pnames)[0];
        if par_eid in claimed { break; }
        claimed[par_eid] = True;
        chain.append(par_eid);
        nxt = _resolve_entity(par_eid);
        if nxt is None { break; }
        cur = nxt;
    }
    return chain;
}

def entity_counts(graph: dict) -> dict[str, int] {
    ents = graph["entities"] as dict[str, dict];
    active = 0;
    tombstone = 0;
    for eid in ents.keys() {
        ent = ents[eid];
        if ent.get("tombstone") { tombstone += 1; } else { active += 1; }
    }
    return {"active": active, "tombstone": tombstone, "total": len(ents)};
}

def canonical_export(graph: dict) -> dict {
    ents = graph["entities"] as dict[str, dict];
    facts = graph["facts"] as dict[str, list[dict]];
    dep_fwd = graph["dep_fwd"] as dict[str, list[str]];
    parent = graph["parent"] as dict[str, str];
    entities = sorted(ents.values(), key=_entity_sort_key);
    facts_out: list[dict] = [];
    for eid in sorted(facts.keys()) {
        rows = sorted(facts[eid], key=_fact_sort_key);
        for fact in rows { facts_out.append(dict(fact)); }
    }
    depends_out: list[tuple[str, str]] = [];
    for (dependent, deps) in dep_fwd.items() {
        for dependency in deps {
            depends_out.append((dependent, dependency));
        }
    }
    depends_out = sorted(depends_out);
    parents_out = sorted(parent.items());
    ent_out: list[dict] = [];
    for ent in entities { ent_out.append(dict(ent)); }
    return {
        "version": "1",
        "entities": ent_out,
        "facts": facts_out,
        "depends": depends_out,
        "parents": parents_out,
    };
}

def canonical_import(bundle: dict) -> dict {
    if bundle.get("version") != "1" {
        raise ValueError("unsupported export version");
    }
    depends: list[tuple[str, str]] = [];
    dep_list = bundle["depends"] as list;
    for pair in dep_list {
        depends.append((pair[0], pair[1]));
    }
    parent_pairs: list[tuple[str, str]] = [];
    par_list = bundle["parents"] as list;
    for pair in par_list {
        parent_pairs.append((pair[0], pair[1]));
    }
    return make_knowledge_graph(
        bundle["entities"],
        bundle["facts"],
        depends,
        parent_pairs,
    );
}

test "diamond revisit upstream deps hop budget" {
    g = make_knowledge_graph(
        [
            {"id": "apex"},
            {"id": "left"},
            {"id": "right"},
            {"id": "hub"},
        ],
        [],
        [
            ("apex", "left"),
            ("apex", "right"),
            ("left", "hub"),
            ("right", "hub"),
        ],
        [],
    );
    assert upstream_dependencies(g, "apex", 8) == ["hub", "left", "right"];;
    assert upstream_dependencies(g, "apex", 1) == ["left", "right"];;
    assert upstream_dependencies(g, "hub", 8) == [];;
}

test "diamond revisit downstream dependents hop budget" {
    g = make_knowledge_graph(
        [
            {"id": "apex"},
            {"id": "left"},
            {"id": "right"},
            {"id": "hub"},
        ],
        [],
        [
            ("apex", "left"),
            ("apex", "right"),
            ("left", "hub"),
            ("right", "hub"),
        ],
        [],
    );
    assert downstream_dependents(g, "hub", 8) == ["apex", "left", "right"];;
    assert downstream_dependents(g, "hub", 1) == ["left", "right"];;
    assert downstream_dependents(g, "apex", 8) == [];;
}

test "unknown id tolerance across knowledge queries" {
    g = make_knowledge_graph(
        [{"id": "only"}],
        [{"entity_id": "only", "key": "k"}],
        [],
        [],
    );
    assert get_entity(g, "ghost") is None;;
    assert query_facts(g, "ghost") == [];;
    assert upstream_dependencies(g, "ghost", 5) == [];;
    assert downstream_dependents(g, "ghost", 5) == [];;
    assert depends_path(g, "ghost", "only") == [];;
    assert depends_path(g, "only", "ghost") == [];;
    assert lineage_to_root(g, "ghost") == [];;
    assert entity_counts(g) == {"active": 1, "tombstone": 0, "total": 1};;
}

test "parent lineage cycle stops without revisit" {
    g = make_knowledge_graph(
        [{"id": "a"}, {"id": "b"}, {"id": "c"}],
        [],
        [],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert lineage_to_root(g, "a") == ["a", "b", "c"];;
    assert lineage_to_root(g, "b") == ["b", "c", "a"];;
    assert lineage_to_root(g, "missing") == [];;
}

test "depends cycle upstream closure skip revisit" {
    g = make_knowledge_graph(
        [{"id": "a"}, {"id": "b"}, {"id": "c"}, {"id": "d"}],
        [],
        [
            ("a", "b"),
            ("b", "c"),
            ("c", "a"),
            ("c", "d"),
        ],
        [],
    );
    assert upstream_dependencies(g, "a", 8) == ["b", "c", "d"];;
    assert upstream_dependencies(g, "d", 8) == [];;
    assert depends_path(g, "a", "d") == ["a", "b", "c", "d"];;
    assert depends_path(g, "d", "a") == [];;
}

test "facts valid_at ordering tombstones and import version guard" {
    g = make_knowledge_graph(
        [
            {"id": "live"},
            {"id": "dead", "tombstone": True},
            {"id": "also"},
        ],
        [
            {"entity_id": "live", "key": "z", "valid_at": "2024"},
            {"entity_id": "live", "key": "z", "valid_at": ""},
            {"entity_id": "live", "key": "a", "valid_at": "2020"},
        ],
        [],
        [],
    );
    assert query_facts(g, "live") == [
        {"entity_id": "live", "key": "a", "valid_at": "2020"},
        {"entity_id": "live", "key": "z", "valid_at": ""},
        {"entity_id": "live", "key": "z", "valid_at": "2024"},
    ];;
    assert entity_counts(g) == {"active": 2, "tombstone": 1, "total": 3};;
    bundle = canonical_export(g);
    g2 = canonical_import(bundle);
    assert canonical_export(g2) == bundle;;
    try {
        canonical_import({"version": "2", "entities": [], "facts": [], "depends": [], "parents": []});
        assert False;;
    } except ValueError {
        assert True;;
    }
}
