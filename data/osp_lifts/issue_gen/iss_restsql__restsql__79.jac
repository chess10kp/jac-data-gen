"""restsql/restsql#79 — recursive geographic descendant closure."""

node Geo {
    has gid: int;
    has parent_id: int;
}

edge GeoChild {}

walker GeoDescendWalker {
    has claimed: dict[str, bool] = {};
    has results: list[tuple[int, int]] = [];

    can descend with Geo entry {
        key = str(here.gid);
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;
        self.results.append((here.gid, here.parent_id));
        print(f"geo id={here.gid} parent={here.parent_id}");
        kids: list[Geo] = [];
        for ch in [here ->:GeoChild:->][?:Geo] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def build_geo_graph(rows: list[tuple[int, int]]) -> tuple[Geo, dict[int, Geo]] {
    nodes: dict[int, Geo] = {};
    graph_anchor = Geo(gid=-1, parent_id=-1);
    root ++> graph_anchor;
    for row in rows {
        gid = row[0];
        pid = row[1];
        if gid not in nodes {
            nd = Geo(gid=gid, parent_id=pid);
            nodes[gid] = nd;
            graph_anchor ++> nd;
        }
    }
    for row in rows {
        gid = row[0];
        pid = row[1];
        if pid in nodes {
            pa = nodes[pid];
            ch = nodes[gid];
            pa +>:GeoChild:+> ch;
        }
    }
    return (graph_anchor, nodes);
}

def recursive_geo(seed_ids: list[int], rows: list[tuple[int, int]]) -> list[tuple[int, int]] {
    built = build_geo_graph(rows);
    nodes = built[1] as dict[int, Geo];
    claimed: dict[str, bool] = {};
    results: list[tuple[int, int]] = [];
    for sid in seed_ids {
        if sid in nodes {
            start = nodes[sid];
            wk = start spawn GeoDescendWalker(claimed=claimed, results=results);
        }
    }
    ordered: list[tuple[int, int]] = sorted(results);
    return ordered;
}
