"""KingPin/Garrul#119 — same-thread parent cycle survives import guards."""

node Comment {
    has cid: str;
    has thread_id: str;
    has declared_parent: str = "";
}

edge Parent {}

walker CycleDetect {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    has cycle_members: list[str] = [];
    has found: bool = False;

    can ascend with Comment entry {
        print("probe ", here.cid);
        if here.cid in self.claimed {
            self.found = True;
            idx: int = -1;
            for i in range(len(self.chain)) {
                if self.chain[i] == here.cid {
                    idx = i;
                    break;
                }
            }
            if idx >= 0 {
                self.cycle_members = [];
                for j in range(idx, len(self.chain)) {
                    self.cycle_members.append(self.chain[j]);
                }
            }
            skip;
        }
        self.claimed[here.cid] = True;
        self.chain.append(here.cid);
        ups: list[Comment] = [here <-:Parent:<-][?:Comment];
        if ups {
            visit ups;
        } else {
            disengage;
        }
    }
}

def _declared_parent(row: dict) -> str {
    if "declared_parent" in row {
        return row["declared_parent"] as str;
    }
    return "";
}

def _rows_to_store(rows: list[dict]) -> dict[str, Comment] {
    store: dict[str, Comment] = {};
    for row in rows {
        cid = row["id"] as str;
        nd = Comment(
            cid=cid,
            thread_id=row["thread_source_id"] as str,
            declared_parent=_declared_parent(row)
        );
        root ++> nd;
        store[cid] = nd;
    }
    return store;
}

def _connect_same_thread(store: dict[str, Comment], rows: list[dict]) {
    for row in rows {
        cid = row["id"] as str;
        pid = _declared_parent(row);
        if pid == "" {
            continue;
        }
        if pid == cid {
            continue;
        }
        if cid not in store {
            continue;
        }
        if pid not in store {
            continue;
        }
        child = store[cid];
        par = store[pid];
        if child.thread_id != par.thread_id {
            continue;
        }
        child +>:Parent:+> par;
    }
}

def _collect_cycle_ids(store: dict[str, Comment]) -> list[str] {
    merged: list[str] = [];
    for cid in store {
        wk = store[cid] spawn CycleDetect(
            claimed={},
            chain=[],
            cycle_members=[],
            found=False
        );
        if wk.found {
            for mid in wk.cycle_members {
                if mid not in merged {
                    merged.append(mid);
                }
            }
        }
    }
    return merged;
}

def _disconnect_parents(nd: Comment) {
    ups: list[Comment] = [nd <-:Parent:<-][?:Comment];
    for par in ups {
        nd del-- Parent -- par;
    }
}

def build_effective_parent(rows: list[dict]) -> dict[str, str | None] {
    store = _rows_to_store(rows);
    _connect_same_thread(store, rows);
    cycle_ids = _collect_cycle_ids(store);
    for cid in cycle_ids {
        if cid in store {
            _disconnect_parents(store[cid]);
        }
    }
    effective: dict[str, str | None] = {};
    for row in rows {
        cid = row["id"] as str;
        pid = _declared_parent(row);
        if cid in cycle_ids {
            effective[cid] = None;
            continue;
        }
        if pid == "" {
            effective[cid] = None;
            continue;
        }
        if pid == cid {
            effective[cid] = None;
            continue;
        }
        if pid not in store {
            effective[cid] = None;
            continue;
        }
        if store[cid].thread_id != store[pid].thread_id {
            effective[cid] = None;
            continue;
        }
        effective[cid] = pid;
    }
    return effective;
}

def depth_of(
    parent_map: dict[str, str | None],
    cid: str,
    seen: dict[str, bool] | None = None
) -> int {
    if seen is None {
        seen = {};
    }
    if cid in seen {
        return 1;
    }
    seen[cid] = True;
    par = parent_map.get(cid, None);
    if par is None {
        return 0;
    }
    return 1 + depth_of(parent_map, par, seen);
}

def select_roots(parent_map: dict[str, str | None]) -> list[str] {
    roots: list[str] = [];
    for cid in parent_map {
        if parent_map[cid] is None {
            roots.append(cid);
        }
    }
    return sorted(roots);
}

def import_comments(rows: list[dict]) -> dict[str, any] {
    effective = build_effective_parent(rows);
    roots = select_roots(effective);
    rerooted: list[str] = [];
    for cid in effective {
        if effective[cid] is None {
            pid = _declared_parent(rows[0]);
            for row in rows {
                if row["id"] as str == cid {
                    pid = _declared_parent(row);
                    break;
                }
            }
            if pid != "" {
                rerooted.append(cid);
            }
        }
    }
    for row in rows {
        cid = row["id"] as str;
        pid = _declared_parent(row);
        if pid == cid and cid not in rerooted {
            rerooted.append(cid);
        }
    }
    return {
        "effective_parent": effective,
        "roots": roots,
        "rerooted": sorted(rerooted)
    };
}
