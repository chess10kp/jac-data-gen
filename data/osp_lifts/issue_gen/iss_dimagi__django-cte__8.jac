"""Recursive CTE descendant rows — dimagi/django-cte#8."""

node GraphHub {
    has by_id: dict[str, Annotation] = {};
}

node Annotation {
    has cid: str;
    has uuid: str;
}

edge Depends {}

walker CteWalker {
    has claimed: dict[str, bool] = {};
    has rows: list[dict] = [];
    has depth: int = 0;

    can walk with Annotation entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        row: dict[str, any] = {};
        row["id"] = here.cid;
        row["uuid"] = here.uuid;
        row["depth"] = self.depth;
        self.rows.append(row);
        print([here.cid, self.depth]);
        kids: list[Annotation] = [];
        for ch in [here ->:Depends:->][?:Annotation] {
            kids.append(ch);
        }
        if kids {
            nd = self.depth + 1;
            for kid in kids {
                kid spawn CteWalker(
                    claimed=self.claimed,
                    rows=self.rows,
                    depth=nd
                );
            }
        }
        disengage;
    }
}

walker DemoWalk {
    can show with GraphHub entry {
        print(["django-cte-8", len(here.by_id)]);
        disengage;
    }
}

def make_hub -> GraphHub {
    hub = GraphHub();
    root ++> hub;
    return hub;
}

def add_annotation(hub: GraphHub, ann_id: str, uuid: str) -> Annotation {
    if ann_id in hub.by_id {
        return hub.by_id[ann_id];
    }
    nd = Annotation(cid=ann_id, uuid=uuid);
    hub ++> nd;
    hub.by_id[ann_id] = nd;
    return nd;
}

def add_dependency(hub: GraphHub, parent_id: str, child_id: str) -> bool {
    if parent_id not in hub.by_id {
        return False;
    }
    if child_id not in hub.by_id {
        return False;
    }
    parent = hub.by_id[parent_id];
    child = hub.by_id[child_id];
    parent +>:Depends:+> child;
    return True;
}

def sort_cte_rows(rows: list[dict]) -> list[dict] {
    keys: list[str] = [];
    for row in rows {
        keys.append(str(row["depth"]) + "\x00" + str(row["id"]));
    }
    sk = sorted(keys);
    out: list[dict] = [];
    for k in sk {
        for row in rows {
            rk = str(row["depth"]) + "\x00" + str(row["id"]);
            if rk == k {
                out.append(row);
            }
        }
    }
    return out;
}

def recursive_cte_rows(hub: GraphHub, root_ids: list[str]) -> list[dict] {
    rows: list[dict] = [];
    claimed: dict[str, bool] = {};
    roots: list[Annotation] = [];
    for rid in root_ids {
        if rid in hub.by_id {
            roots.append(hub.by_id[rid]);
        }
    }
    for r in roots {
        r spawn CteWalker(claimed=claimed, rows=rows, depth=0);
    }
    return sort_cte_rows(rows);
}

with entry {
    hub = make_hub();
    add_annotation(hub, "seed", "u-seed");
    recursive_cte_rows(hub, ["seed"]);
    root spawn DemoWalk();
}
