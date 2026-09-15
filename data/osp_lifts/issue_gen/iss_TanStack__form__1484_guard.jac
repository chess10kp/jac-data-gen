"""TanStack/form#1484 — recursive field value traversal, depth limits, reactions."""

node Field {
    has fid: str;
    has key: str;
    has kind: str;
    has prim: object = None;
    has path: str;
    has depth: int = 0;
}

edge Child {}

obj BuildCtx {
    has seq: int = 0;
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has paths: list[str] = [];
    has max_depth: int = 0;

    can step with Field entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        print("collect", here.path, here.kind);
        if here.kind == "primitive" {
            self.paths.append(here.path);
        }
        if here.depth > self.max_depth {
            self.max_depth = here.depth;
        }
        kids: list[Field] = [here ->:Child:->][?:Field];
        for ch in kids {
            visit ch;
        }
    }
}

walker ReactWalker {
    has claimed: dict[str, bool] = {};
    has changed: list[str] = [];
    has hits: list[str] = [];

    can step with Field entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        print("react", here.path);
        for cp in self.changed {
            if here.path == cp {
                self.hits.append(here.path);
            } elif len(cp) > len(here.path) and cp.startswith(here.path) {
                nxt = cp[len(here.path)];
                if nxt == "." or nxt == "[" {
                    self.hits.append(here.path);
                }
            } elif len(here.path) > len(cp) and here.path.startswith(cp) {
                nxt = here.path[len(cp)];
                if nxt == "." or nxt == "[" {
                    self.hits.append(here.path);
                }
            }
        }
        kids: list[Field] = [here ->:Child:->][?:Field];
        for ch in kids {
            visit ch;
        }
    }
}

walker ExistsWalker {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: bool = False;

    can probe with Field entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        print("exists", here.path);
        if here.path == self.target {
            self.found = True;
        }
        kids: list[Field] = [here ->:Child:->][?:Field];
        for ch in kids {
            visit ch;
        }
    }
}

def next_fid(ctx: BuildCtx) -> str {
    ctx.seq += 1;
    return "f" + str(ctx.seq);
}

def add_primitive(parent: Field, key: str, path: str, depth: int, val: object, ctx: BuildCtx) -> Field {
    nd = Field(fid=next_fid(ctx), key=key, kind="primitive", prim=val, path=path, depth=depth);
    parent +>:Child:+> nd;
    return nd;
}

def ingest_dict(parent: Field, values: dict, ctx: BuildCtx, prefix: str) {
    for key in values {
        val = values[key];
        path = key;
        if prefix != "" {
            path = prefix + "." + key;
        }
        depth = parent.depth + 1;
        if isinstance(val, dict) {
            nd = Field(fid=next_fid(ctx), key=key, kind="object", prim=None, path=path, depth=depth);
            parent +>:Child:+> nd;
            ingest_dict(nd, val, ctx, path);
        } elif isinstance(val, list) {
            arr_nd = Field(fid=next_fid(ctx), key=key, kind="array", prim=None, path=path, depth=depth);
            parent +>:Child:+> arr_nd;
            idx = 0;
            for item in val {
                ipath = path + "[" + str(idx) + "]";
                idx += 1;
                if isinstance(item, dict) {
                    item_nd = Field(fid=next_fid(ctx), key=str(idx - 1), kind="object", prim=None, path=ipath, depth=depth + 1);
                    arr_nd +>:Child:+> item_nd;
                    ingest_dict(item_nd, item, ctx, ipath);
                } else {
                    add_primitive(arr_nd, str(idx - 1), ipath, depth + 1, item, ctx);
                }
            }
        } else {
            add_primitive(parent, key, path, depth, val, ctx);
        }
    }
}

def create_field_graph(values: dict) -> Field {
    ctx = BuildCtx();
    graph_root = Field(fid=next_fid(ctx), key="", kind="object", prim=None, path="", depth=0);
    root ++> graph_root;
    ingest_dict(graph_root, values, ctx, "");
    return graph_root;
}

def unique_sorted(items: list[str]) -> list[str] {
    seen: dict[str, bool] = {};
    for it in items {
        seen[it] = True;
    }
    out: list[str] = [];
    for k in seen {
        out.append(k);
    }
    return sorted(out);
}

def collect_leaf_paths(graph_root: Field) -> list[str] {
    wk = graph_root spawn CollectWalker(claimed={});
    return sorted(wk.paths);
}

def measure_max_depth(graph_root: Field) -> int {
    wk = graph_root spawn CollectWalker(claimed={});
    return wk.max_depth;
}

def depth_exceeds_limit(graph_root: Field, limit: int) -> bool {
    return measure_max_depth(graph_root) > limit;
}

def reaction_paths(graph_root: Field, changed: list[str]) -> list[str] {
    wk = graph_root spawn ReactWalker(claimed={}, changed=changed);
    return unique_sorted(wk.hits);
}

def has_field_path(graph_root: Field, target: str) -> bool {
    if target == "" {
        return True;
    }
    wk = graph_root spawn ExistsWalker(claimed={}, target=target);
    return wk.found;
}

test "leaf_paths_sorted" {
    g = create_field_graph({"a": 1, "b": {"c": 2}});
    assert collect_leaf_paths(g) == ["a", "b.c"];
}

test "max_depth_nested" {
    g = create_field_graph({"x": {"y": {"z": 1}}});
    assert measure_max_depth(g) == 3;
}

test "depth_limit" {
    shallow = create_field_graph({"a": 1});
    deep = create_field_graph({"a": {"b": {"c": {"d": 1}}}});
    assert depth_exceeds_limit(shallow, 5) == False;
    assert depth_exceeds_limit(deep, 2) == True;
}

test "reaction_prefix" {
    g = create_field_graph({"user": {"name": "x", "age": 1}});
    assert reaction_paths(g, ["user.name"]) == ["user", "user.name"];
}

test "has_field_path" {
    g = create_field_graph({"items": [1, 2]});
    assert has_field_path(g, "items[0]") == True;
    assert has_field_path(g, "missing") == False;
    assert has_field_path(g, "") == True;
}

test "array_nested_object" {
    g = create_field_graph({"arr": [{"k": 1}]});
    assert collect_leaf_paths(g) == ["arr[0].k"];
}
