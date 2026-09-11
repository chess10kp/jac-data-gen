"""maui314159/navigatsql#5"""

node N {
    has cid: str;
    has kind: str;
    has name: str;
}

edge E {
    has tag: str;
    has provenance: list[str] = [];
}

obj Catalog {
    has nodes: dict[str, N] = {};
    has links: dict[str, bool] = {};
    has results: list[str] = [];
}

walker Users {
    has claimed: dict[str, bool] = {};
    has catalog: Catalog;
    has target: str;

    can start with entry {
        self.catalog.results = [];
        let start = self.catalog.nodes[self.target];
        visit :0: [start];
    }

    can step with N entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print here.cid;
        if here.kind == "definition" {
            self.catalog.results.append(here.name);
        }
        for parent in [here <-:E:<-][?:N] {
            visit :0: [parent];
        }
    }
}

def construct_node(catalog: Catalog, construct_kind: str) -> N {
    let cid = "construct:" + construct_kind;
    if cid not in catalog.nodes {
        let node = N(cid=cid, kind="construct", name=construct_kind);
        catalog.nodes[cid] = node;
    }
    return catalog.nodes[cid];
}

def add_definition(catalog: Catalog, definition_id: str, name: str) -> N {
    if definition_id not in catalog.nodes {
        let node = N(cid=definition_id, kind="definition", name=name);
        catalog.nodes[definition_id] = node;
    }
    return catalog.nodes[definition_id];
}

def add_usage(
    catalog: Catalog,
    definition_id: str,
    construct_kind: str,
    provenance: str
) {
    if definition_id not in catalog.nodes { return; }
    let parent = catalog.nodes[definition_id];
    let child = construct_node(catalog, construct_kind);
    let pair = definition_id + "|" + construct_kind;
    if pair not in catalog.links {
        let link = E(
            tag="custom:uses_" + construct_kind,
            provenance=[provenance]
        );
        parent +>:link:+> child;
        catalog.links[pair] = True;
    }
}

def users_of(catalog: Catalog, construct_kind: str) -> list[str] {
    let target = "construct:" + construct_kind;
    if target not in catalog.nodes { return []; }
    with entry {
        root spawn Users(catalog=catalog, target=target);
    }
    return sorted(catalog.results);
}

test "diamond revisit returns each definition once" {
    let c = Catalog();
    add_definition(c, "proc:a", "A");
    add_definition(c, "proc:b", "B");
    add_usage(c, "proc:a", "recursive_cte", "a.sql");
    add_usage(c, "proc:b", "recursive_cte", "b.sql");
    add_usage(c, "proc:a", "cursor", "a.sql");
    add_usage(c, "proc:b", "cursor", "b.sql");
    let c1 = c.nodes["construct:cursor"];
    let c2 = c.nodes["construct:recursive_cte"];
    c2 +>:E(tag="custom:related", provenance=[]):+> c1;
    assert (users_of(c, "cursor") == ["A", "B"]);
}

test "duplicate occurrences produce one edge result" {
    let c = Catalog();
    add_definition(c, "qry:tree", "TreeWalk");
    add_usage(c, "qry:tree", "recursive_cte", "SQL/a.sql");
    add_usage(c, "qry:tree", "recursive_cte", "SQL/a.sql");
    add_usage(c, "qry:tree", "recursive_cte", "SQL/b.sql");
    assert (users_of(c, "recursive_cte") == ["TreeWalk"]);
}

test "unknown construct is tolerated" {
    let c = Catalog();
    add_definition(c, "proc:p", "P");
    assert (users_of(c, "missing_construct") == []);
}

test "unknown definition is ignored" {
    let c = Catalog();
    add_usage(c, "proc:missing", "dynamic_sql", "missing.sql");
    assert (users_of(c, "dynamic_sql") == []);
}

test "multiple construct kinds remain distinct" {
    let c = Catalog();
    add_definition(c, "proc:p", "P");
    add_usage(c, "proc:p", "cursor", "p.sql");
    add_usage(c, "proc:p", "dynamic_sql", "p.sql");
    assert (users_of(c, "cursor") == ["P"]);
    assert (users_of(c, "dynamic_sql") == ["P"]);
}
