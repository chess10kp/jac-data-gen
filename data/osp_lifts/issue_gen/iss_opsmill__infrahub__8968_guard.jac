"""Schema profile hierarchy resolution, lifted to OSP.

Kinds are ``Kind`` nodes; ``parent`` pointers become typed ``Extends``
edges. Root resolution and lineage climb the typed edges with one
walker whose seen-set is the explicit cycle policy: the self-parenting
corruption from issue #8968 raises ``SchemaCycleError`` instead of
recursing forever.
"""

class SchemaCycleError(ValueError) {}

node Kind {
    has name: str;
}

edge Extends: Kind --> Kind {}

node SchemaRoot {}

"""Fresh hierarchy root."""
def new_hierarchy() -> SchemaRoot {
    root ++> (r := SchemaRoot());
    return r;
}

def _find_kind(h: SchemaRoot, kind: str) -> Kind | None {
    hits = [k for k in [h -->][?:Kind] if k.name == kind];
    if len(hits) == 0 {
        return None;
    }
    return hits[0];
}

"""Register a kind; a self-parent is accepted, as in the source."""
def register_kind(h: SchemaRoot, kind: str, parent_kind: str | None = None) -> None {
    if _find_kind(h, kind) is not None {
        raise ValueError("duplicate kind");
    }
    root ++> (k := Kind(name=kind));
    h ++> k;
    if parent_kind is not None {
        p = _find_kind(h, parent_kind);
        if p is None {
            raise KeyError("unknown parent kind");
        }
        k +>:Extends:+> p;
    }
}

walker RootClimb {
    """Climbs Extends edges; flags a revisit instead of looping."""
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    has hit_cycle: bool = False;

    can step with Kind entry {
        if here.name in self.claimed {
            self.hit_cycle = True;
            skip;
        }
        self.claimed[here.name] = True;
        self.chain.append(here.name);
        visit [->:Extends:->];
    }
}

def _climb(h: SchemaRoot, kind: str) -> list[str] {
    k = _find_kind(h, kind);
    if k is None {
        raise KeyError("unknown kind");
    }
    w = k spawn RootClimb();
    if w.hit_cycle {
        raise SchemaCycleError("hierarchy cycle");
    }
    return w.chain;
}

"""The most distant ancestor kind name."""
def resolve_root(h: SchemaRoot, kind: str) -> str {
    chain = _climb(h, kind);
    return chain[-1];
}

"""Ancestor kinds nearest-first; raises on cycle."""
def lineage(h: SchemaRoot, kind: str) -> list[str] {
    chain = _climb(h, kind);
    return chain[1:];
}

"""Sorted direct child kinds of `kind`."""
def children_of(h: SchemaRoot, kind: str) -> list[str] {
    k = _find_kind(h, kind);
    if k is None {
        raise KeyError("unknown kind");
    }
    return sorted(c.name for c in [k <-:Extends:<-]);
}

test "resolve root and lineage on acyclic profile tree" {
    h = new_hierarchy();
    register_kind(h, "CoreGenericProfile");
    register_kind(h, "AristaGenericProfile", "CoreGenericProfile");
    register_kind(h, "AristaPortProfile", "AristaGenericProfile");
    assert resolve_root(h, "AristaPortProfile") == "CoreGenericProfile";
    assert lineage(h, "AristaPortProfile") == ["AristaGenericProfile", "CoreGenericProfile"];
    assert lineage(h, "CoreGenericProfile") == [];
    assert children_of(h, "AristaGenericProfile") == ["AristaPortProfile"];
    assert resolve_root(h, "AristaGenericProfile") == "CoreGenericProfile";
}

test "self-parent corruption raises SchemaCycleError" {
    h = new_hierarchy();
    register_kind(h, "AristaPortProfile");
    k = _find_kind(h, "AristaPortProfile");
    k +>:Extends:+> k;
    raised = False;
    try {
        resolve_root(h, "AristaPortProfile");
    } except SchemaCycleError {
        raised = True;
    }
    assert raised;
    raised = False;
    try {
        lineage(h, "AristaPortProfile");
    } except SchemaCycleError {
        raised = True;
    }
    assert raised;
}

test "multi-hop loop raises SchemaCycleError" {
    h = new_hierarchy();
    register_kind(h, "a");
    register_kind(h, "b", "a");
    register_kind(h, "c", "b");
    a = _find_kind(h, "a");
    c = _find_kind(h, "c");
    a del <-:Extends:<- c;
    c +>:Extends:+> a;
    raised = False;
    try {
        resolve_root(h, "c");
    } except SchemaCycleError {
        raised = True;
    }
    assert raised;
}
