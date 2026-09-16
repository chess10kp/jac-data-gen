"""NCEAS/metacat#1429 — closure table for version chains."""

node Version {
    has guid: str;
}

edge Obsoletes {}

def create_store -> dict {
    store: dict = {};
    store["versions"] = {};
    store["direct_parent"] = {};
    store["direct_child"] = {};
    store["closure"] = [];
    return store;
}

def _ensure_version(store: dict, guid: str) -> Version {
    versions = store["versions"] as dict[str, Version];
    if guid in versions {
        return versions[guid];
    }
    nd = Version(guid=guid);
    root ++> nd;
    versions[guid] = nd;
    return nd;
}

def register_version(store: dict, guid: str) {
    _ensure_version(store, guid);
}

def add_obsoletes_link(store: dict, parent_guid: str, child_guid: str) {
    parent_nd = _ensure_version(store, parent_guid);
    child_nd = _ensure_version(store, child_guid);
    parent_nd +>:Obsoletes:+> child_nd;
    dp = store["direct_parent"] as dict[str, str];
    dc = store["direct_child"] as dict[str, str];
    dp[child_guid] = parent_guid;
    dc[parent_guid] = child_guid;
}

walker CollectDesc {
    has origin: str;
    has rows: list[list];
    has claimed: dict[str, bool] = {};
    has cur_depth: int = 0;

    can step with Version entry {
        if here.guid in self.claimed {
            skip;
        }
        self.claimed[here.guid] = True;
        row: list = [];
        row.append(self.origin);
        row.append(here.guid);
        row.append(self.cur_depth);
        self.rows.append(row);
        print "closure", self.origin, here.guid, self.cur_depth;
        kids: list[Version] = [here ->:Obsoletes:->][?:Version];
        for ch in kids {
            wk = ch spawn CollectDesc(
                origin=self.origin,
                rows=self.rows,
                claimed=self.claimed,
                cur_depth=self.cur_depth + 1
            );
        }
    }
}

def rebuild_closure_table(store: dict) -> list {
    versions = store["versions"] as dict[str, Version];
    all_rows: list[list] = [];
    keys: list[str] = [];
    for g in versions {
        keys.append(g);
    }
    keys = sorted(keys);
    for og in keys {
        nd = versions[og];
        rows: list[list] = [];
        claimed: dict[str, bool] = {};
        wk = nd spawn CollectDesc(origin=og, rows=rows, claimed=claimed, cur_depth=0);
        for r in rows {
            all_rows.append(r);
        }
    }
    store["closure"] = all_rows;
    return sorted(all_rows);
}

def get_descendants(store: dict, guid: str) -> list {
    versions = store["versions"] as dict[str, Version];
    if guid not in versions {
        return [];
    }
    closure = store["closure"] as list[list];
    result: list[list] = [];
    for row in closure {
        if row[0] == guid and row[2] > 0 {
            pair: list = [];
            pair.append(row[1]);
            pair.append(row[2]);
            result.append(pair);
        }
    }
    return sorted(result);
}

def get_ancestors(store: dict, guid: str) -> list {
    versions = store["versions"] as dict[str, Version];
    if guid not in versions {
        return [];
    }
    closure = store["closure"] as list[list];
    result: list[list] = [];
    for row in closure {
        if row[1] == guid and row[2] > 0 {
            pair: list = [];
            pair.append(row[0]);
            pair.append(row[2]);
            result.append(pair);
        }
    }
    return sorted(result);
}

def get_direct_parent(store: dict, guid: str) -> str | None {
    dp = store["direct_parent"] as dict[str, str];
    if guid not in dp {
        return None;
    }
    return dp[guid];
}

def get_direct_child(store: dict, guid: str) -> str | None {
    dc = store["direct_child"] as dict[str, str];
    if guid not in dc {
        return None;
    }
    return dc[guid];
}

walker DemoWalk {
    can boot with entry {
        print "metacat#1429 closure-table demo";
        visit [-->][?:Version];
    }

    can step with Version entry {
        print "version", here.guid;
    }
}

with entry {
    st = create_store();
    register_version(st, "P1");
    register_version(st, "P2");
    add_obsoletes_link(st, "P2", "P1");
    rebuild_closure_table(st);
    root spawn DemoWalk;
}
