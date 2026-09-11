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
