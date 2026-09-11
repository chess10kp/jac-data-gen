"""edjafarov/kiagent-core#75 — bounded recursive CTE reachability off sync query_sql."""

glob DEFAULT_ROW_CAP = 500;

node SqlTable {
    has tid: str;
    has row_count: int = 0;
}

edge FkRef {}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has row_cap: int = 0;
    has rows_used: int = 0;
    has truncated: bool = False;

    can step with SqlTable entry {
        if here.tid in self.claimed { skip; }
        if self.row_cap > 0 and self.rows_used + here.row_count > self.row_cap {
            self.truncated = True;
            disengage;
        }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        self.rows_used += here.row_count;
        kids = _sorted_children(here);
        idx = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx -= 1;
        }
    }
}

def _sorted_children(nd: SqlTable) -> list[SqlTable] {
    kids: list[SqlTable] = [];
    for ch in [nd ->:FkRef:->][?:SqlTable] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.tid); }
    names = sorted(names);
    ordered: list[SqlTable] = [];
    for nm in names {
        for ch in kids { if ch.tid == nm { ordered.append(ch); } }
    }
    return ordered;
}

def _find_table(tid: str, store: dict) -> SqlTable | None {
    nmap = store["nodes"] as dict[str, SqlTable];
    if tid in nmap { return nmap[tid]; }
    return None;
}

def fresh_query_store() -> dict { return {"tables": {}, "refs": {}, "nodes": {}}; }

def register_table(table_id: str, row_count: int, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_query_store(); }
    tmap = s["tables"] as dict[str, int];
    tmap[table_id] = row_count;
    refs = s["refs"] as dict[str, list[str]];
    if table_id not in refs { refs[table_id] = []; }
    nmap = s["nodes"] as dict[str, SqlTable];
    nd = SqlTable(tid=table_id, row_count=row_count);
    root ++> nd;
    nmap[table_id] = nd;
    return s;
}

def add_reference(source_id: str, target_id: str, store: dict) {
    tmap = store["tables"] as dict;
    if source_id not in tmap or target_id not in tmap { raise KeyError("unknown table id"); }
    src_nd = _find_table(source_id, store);
    tgt_nd = _find_table(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:FkRef:->][?:SqlTable] { if ex.tid == target_id { seen = True; } }
        if not seen { src_nd +>:FkRef:+> tgt_nd; }
    }
    outs = store["refs"] as dict[str, list[str]];
    if source_id not in outs { outs[source_id] = []; }
    lst = outs[source_id] as list[str];
    if target_id not in lst { lst.append(target_id); }
}

def recursive_reachable(start_id: str, store: dict, row_cap: int = DEFAULT_ROW_CAP) -> list[str] {
    if start_id not in (store["tables"] as dict) { raise KeyError(start_id); }
    start_nd = _find_table(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachWalk(claimed={}, order=[], row_cap=row_cap, rows_used=0, truncated=False);
    return w.order;
}

def query_work_units(start_id: str, store: dict) -> int {
    order = recursive_reachable(start_id, store, row_cap=0);
    tmap = store["tables"] as dict[str, int];
    total = 0;
    for tid in order { total += tmap[tid]; }
    return total;
}

def bounded_reach_report(start_id: str, store: dict, row_cap: int = DEFAULT_ROW_CAP) -> dict {
    if start_id not in (store["tables"] as dict) { raise KeyError(start_id); }
    start_nd = _find_table(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachWalk(claimed={}, order=[], row_cap=row_cap, rows_used=0, truncated=False);
    return {"tables": w.order, "rows": w.rows_used, "truncated": w.truncated};
}
