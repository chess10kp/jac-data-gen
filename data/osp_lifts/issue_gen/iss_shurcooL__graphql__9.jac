# Lift of shurcooL/graphql#9: bounded-depth recursive query rendering.
# Node graph of query fields; a walker expands children up to a max depth.

node Field {
    has name: str;
    has cid: str;
}

edge Child {}

# Render a field subtree as a GraphQL-style query string, bounded by depth.
def write_query(root: Field, max_depth: int) -> str {
    return expand_field(root, 0, max_depth);
}

# Public: build a small comment tree and render it recursively.
def build_tree(names: list[str]) -> list[Field] {
    fields: list[Field] = [];
    for nm in names {
        f = Field(name=nm, cid=nm);
        fields.append(f);
    }
    for i in range(len(fields) - 1) {
        fields[i] +>:Child:+> fields[i + 1];
    }
    return fields;
}

# Public: connect children edges from a parent to a list of nodes.
def link_children(parent: Field, kids: list[Field]) -> None {
    for k in kids {
        parent +>:Child:+> k;
    }
}

# Public: list direct child names of a field.
def child_names(f: Field) -> list[str] {
    out: list[str] = [];
    for ch in [f ->:Child:->][?:Field] {
        out.append(ch.name);
    }
    return sorted(out);
}

# Recursive expansion with explicit depth bound (no claim-map needed;
# depth cap is the termination policy for tree-shaped queries).
def expand_field(f: Field, depth: int, max_depth: int) -> str {
    parts: str = f.name;
    if depth >= max_depth {
        return parts;
    }
    kids: list[Field] = [f ->:Child:->][?:Field];
    inner: list[str] = [];
    for ch in kids {
        inner.append(expand_field(ch, depth + 1, max_depth));
    }
    if len(inner) == 0 {
        return parts;
    }
    body: str = "";
    for i, p in enumerate(inner) {
        if i > 0 { body += " "; }
        body += p;
    }
    return parts + " { " + body + " }";
}

walker ExpandQuery {
    has max_depth: int = 2;
    has claimed: dict[str, bool] = {};
    has visited_order: list[str] = [];

    can step with Field entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.visited_order.append(here.name);
        kids: list[Field] = [here ->:Child:->][?:Field];
        filtered: list[Field] = [];
        for k in kids {
            if here.depth_of(k) <= self.max_depth {
                filtered.append(k);
            }
        }
        if len(filtered) == 0 {
            disengage;
        }
        visit filtered;
    }

    def depth_of(k: Field) -> int {
        return 1;
    }
}

# Public: bounded-depth walk from a root, returning visit order.
def walk_bounded(root: Field, max_depth: int) -> list[str] {
    wk = root spawn ExpandQuery(max_depth=max_depth, claimed={});
    return wk.visited_order;
}

with entry {
    f0 = Field(name="root", cid="r0");
    f1 = Field(name="a", cid="a1");
    f2 = Field(name="b", cid="b2");
    link_children(f0, [f1, f2]);
    print(write_query(f0, 2));
    print(walk_bounded(f0, 2));
}
