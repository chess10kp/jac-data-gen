"""tabulator-tables/tabulator#3020 — deep tree filter exposing ancestor paths."""

node Row {
    has cid: str;
    has values: dict[str, str] = {};
}

edge Child {}

walker FindRow {
    has target_id: str;
    has found: Row | None = None;
    has claimed: dict[str, bool] = {};

    can step with Row entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.target_id {
            self.found = here;
            print("find hit " + here.cid);
            disengage;
        }
        kids: list[Row] = [here ->:Child:->][?:Row];
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker CollectSubtree {
    has rows: list[Row] = [];
    has claimed: dict[str, bool] = {};

    can step with Row entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.rows.append(here);
        kids: list[Row] = [here ->:Child:->][?:Row];
        if kids {
            visit kids;
        } else {
            disengage;
        }
        print("collect " + here.cid);
    }
}

walker MeasureDepth {
    has depths: dict[str, int] = {};
    has claimed: dict[str, bool] = {};
    has base: int = 0;

    can step with Row entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.depths[here.cid] = self.base;
        kids: list[Row] = [here ->:Child:->][?:Row];
        if kids {
            for kid in kids {
                kid spawn MeasureDepth(
                    depths=self.depths,
                    claimed=self.claimed,
                    base=self.base + 1
                );
            }
        } else {
            disengage;
        }
        print("depth " + here.cid + "=" + str(self.base));
    }
}

walker DemoFilter {
    can run entry {
        graph_root = build_location_tree;
        vis = visible_row_ids(graph_root, "world", "yellow", "colour");
        print("demo_visible=" + str(vis));
    }
}

def field_matches(header_value: str, field_value: str | None) -> bool {
    if field_value is None {
        return False;
    }
    hv = header_value.lower();
    fv = field_value.lower();
    return fv.find(hv) >= 0;
}

def clear_match_cache(cache: dict[str, bool]) {
    keys: list[str] = [];
    for k in cache {
        keys.append(k);
    }
    for k in keys {
        del cache[k];
    }
}

def find_row_by_id(graph_root: Row, target_id: str) -> Row | None {
    w = graph_root spawn FindRow(target_id=target_id);
    return w.found;
}

def collect_subtree_rows(start: Row) -> list[Row] {
    w = start spawn CollectSubtree();
    return w.rows;
}

def measure_depths(start: Row) -> dict[str, int] {
    w = start spawn MeasureDepth();
    return w.depths;
}

def deep_match_row(
    graph_root: Row,
    node_id: str,
    header_value: str,
    column_name: str,
    cache: dict[str, bool],
) -> bool {
    if node_id in cache {
        return cache[node_id];
    }
    target = find_row_by_id(graph_root, node_id);
    if target is None {
        return False;
    }
    rows: list[Row] = collect_subtree_rows(target);
    depths: dict[str, int] = measure_depths(target);
    max_d = 0;
    for r in rows {
        d = depths[r.cid];
        if d > max_d {
            max_d = d;
        }
    }
    d = max_d;
    while d >= 0 {
        for r in rows {
            if depths[r.cid] != d {
                continue;
            }
            cid = r.cid;
            if cid in cache {
                continue;
            }
            child_hit = False;
            kids: list[Row] = [r ->:Child:->][?:Row];
            for kid in kids {
                if cache[kid.cid] {
                    child_hit = True;
                    break;
                }
            }
            fv: str | None = None;
            if column_name in r.values {
                fv = r.values[column_name];
            }
            self_hit = field_matches(header_value, fv);
            cache[cid] = child_hit or self_hit;
        }
        d -= 1;
    }
    return cache[node_id];
}

def visible_row_ids(
    graph_root: Row,
    root_id: str,
    header_value: str,
    column_name: str,
) -> list[str] {
    anchor = find_row_by_id(graph_root, root_id);
    if anchor is None {
        return [];
    }
    cache: dict[str, bool] = {};
    deep_match_row(graph_root, root_id, header_value, column_name, cache);
    rows: list[Row] = collect_subtree_rows(anchor);
    out: list[str] = [];
    for r in rows {
        if cache[r.cid] {
            out.append(r.cid);
        }
    }
    out = sorted(out);
    return out;
}

def build_location_tree -> Row {
    world = Row(
        cid="world",
        values={"location": "World", "colour": "blue"},
    );
    root ++> world;
    building = Row(
        cid="building",
        values={"location": "HQ", "colour": "grey"},
    );
    world +>:Child:+> building;
    floor = Row(
        cid="floor",
        values={"location": "Floor 3", "colour": "white"},
    );
    building +>:Child:+> floor;
    desk = Row(
        cid="desk",
        values={"location": "Desk 12", "colour": "yellow"},
    );
    floor +>:Child:+> desk;
    return world;
}

with entry {
    root spawn DemoFilter();
}

test "field_matches_substring_insensitive" {
    assert field_matches("YEL", "yellow");
    assert not field_matches("pink", "yellow");
    assert not field_matches("x", None);
}

test "visible_yellow_includes_ancestors" {
    graph_root = build_location_tree;
    vis = visible_row_ids(graph_root, "world", "yellow", "colour");
    assert vis == ["building", "desk", "floor", "world"];
}

test "visible_blue_only_root" {
    graph_root = build_location_tree;
    vis = visible_row_ids(graph_root, "world", "blue", "colour");
    assert vis == ["world"];
}

test "find_row_by_id_hit_and_miss" {
    graph_root = build_location_tree;
    hit = find_row_by_id(graph_root, "desk");
    miss = find_row_by_id(graph_root, "missing");
    assert hit is not None;
    assert hit.cid == "desk";
    assert miss is None;
}

test "deep_match_row_uses_cache" {
    graph_root = build_location_tree;
    cache: dict[str, bool] = {};
    assert deep_match_row(graph_root, "desk", "yellow", "colour", cache);
    assert cache["desk"];
    assert deep_match_row(graph_root, "desk", "yellow", "colour", cache);
}

test "clear_match_cache_empties" {
    cache: dict[str, bool] = {"desk": True, "floor": True};
    clear_match_cache(cache);
    assert len(cache) == 0;
}
