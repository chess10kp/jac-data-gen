"""tabulator-tables/tabulator#3020 — deep tree header filter with ancestor visibility."""

node TreeRow {
    has cid: str;
    has location: str;
}

edge Child {}

walker FindRowWalker {
    has want: str;
    has got: TreeRow | None = None;
    has claimed: dict[str, bool] = {};

    can step with TreeRow entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ["find", here.cid];
        if here.cid == self.want {
            self.got = here;
            disengage;
        }
        kids: list[TreeRow] = [];
        for ch in [here ->:Child:->][?:TreeRow] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker PostOrderWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with TreeRow entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        kids: list[TreeRow] = [];
        for ch in [here ->:Child:->][?:TreeRow] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        }
        self.order.append(here.cid);
        print ["post", here.cid];
    }
}

def make_filter_cache -> dict[str, bool] {
    cache: dict[str, bool] = {};
    return cache;
}

def clear_filter_cache(cache: dict[str, bool]) {
    keys: list[str] = [];
    for k in cache {
        keys.append(k);
    }
    for k in keys {
        cache.pop(k);
    }
}

def find_row(graph_root: TreeRow, cid: str) -> TreeRow | None {
    w = graph_root spawn FindRowWalker(want=cid);
    return w.got;
}

def col_value(row: TreeRow, column_name: str) -> str | None {
    if column_name == "location" {
        return row.location;
    }
    return None;
}

def str_contains(hay: str, needle: str) -> bool {
    if len(needle) == 0 {
        return True;
    }
    i = 0;
    while i + len(needle) <= len(hay) {
        if hay[i:i + len(needle)] == needle {
            return True;
        }
        i += 1;
    }
    return False;
}

def row_matches(header_value: str, val: str | None) -> bool {
    if val is None {
        return False;
    }
    return str_contains(val.lower(), header_value.lower());
}

def deep_match_header_filter(
    header_value: str,
    row_value: str | None,
    node_id: str,
    graph_root: TreeRow,
    filter_params: dict[str, str],
    cache: dict[str, bool],
) -> bool {
    if node_id in cache {
        return cache[node_id];
    }
    column_name = filter_params["column_name"];
    target = find_row(graph_root, node_id);
    if target is None {
        return False;
    }
    pw = target spawn PostOrderWalker(claimed={});
    i = 0;
    while i < len(pw.order) {
        cid = pw.order[i];
        node = find_row(graph_root, cid);
        if node is not None {
            any_child: bool = False;
            for ch in [node ->:Child:->][?:TreeRow] {
                if ch.cid in cache and cache[ch.cid] {
                    any_child = True;
                }
            }
            val: str | None = row_value;
            if cid != node_id {
                val = col_value(node, column_name);
            }
            cache[cid] = any_child or row_matches(header_value, val);
        }
        i += 1;
    }
    if node_id in cache {
        return cache[node_id];
    }
    return False;
}

def visible_row_ids(
    header_value: str,
    graph_root: TreeRow,
    filter_params: dict[str, str],
    cache: dict[str, bool],
) -> list[str] {
    pw = graph_root spawn PostOrderWalker(claimed={});
    out: list[str] = [];
    i = 0;
    while i < len(pw.order) {
        cid = pw.order[i];
        node = find_row(graph_root, cid);
        if node is not None {
            rv = col_value(node, filter_params["column_name"]);
            if deep_match_header_filter(header_value, rv, cid, graph_root, filter_params, cache) {
                out.append(cid);
            }
        }
        i += 1;
    }
    out.sort();
    return out;
}

def build_demo_tree -> TreeRow {
    world = TreeRow(cid="w", location="World");
    root ++> world;
    eu = TreeRow(cid="eu", location="Europe");
    world +>:Child:+> eu;
    paris = TreeRow(cid="par", location="Paris Yellow Room");
    eu +>:Child:+> paris;
    return world;
}

with entry {
    cache: dict[str, bool] = make_filter_cache();
    g: TreeRow = build_demo_tree();
    params: dict[str, str] = {};
    params["column_name"] = "location";
    ids: list[str] = visible_row_ids("yellow", g, params, cache);
    print ["demo", ids];
    clear_filter_cache(cache);
    root spawn FindRowWalker(want="par");
}
