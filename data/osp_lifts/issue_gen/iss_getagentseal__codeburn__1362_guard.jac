"""Archived OpenCode sessions vanish from discovery and metrics — getagentseal/codeburn#1362."""

node Session {
    has sid: str;
    has tokens: int = 0;
    has archived: bool = False;
    has created: int = 0;
    has path_key: str = "";
}

edge Subagent {}

walker TreeIds {
    has claimed: dict[str, bool] = {};
    has exclude_archived: bool = True;
    has acc: list[str] = [];

    can step with Session entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        if self.exclude_archived and here.archived {
            skip;
        }
        self.acc.append(here.sid);
        print(here.sid);
        kids: list[Session] = [];
        for ch in [here ->:Subagent:->][?:Session] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def build_graph(records: list[dict]) -> dict[str, Session] {
    by_id: dict[str, Session] = {};
    pending: list[dict] = [];
    for rec in records {
        arch: bool = False;
        if "archived" in rec {
            arch = rec["archived"];
        }
        tok: int = 0;
        if "tokens" in rec {
            tok = rec["tokens"];
        }
        cr: int = 0;
        if "created" in rec {
            cr = rec["created"];
        }
        pk: str = rec["id"];
        if "path_key" in rec {
            pk = rec["path_key"];
        }
        s = Session(sid=rec["id"], tokens=tok, archived=arch, created=cr, path_key=pk);
        by_id[rec["id"]] = s;
        pending.append(rec);
    }
    for rec in pending {
        pid: str = "";
        if "parent_id" in rec {
            if rec["parent_id"] != None {
                pid = rec["parent_id"];
            }
        }
        if pid != "" {
            if pid in by_id {
                if rec["id"] in by_id {
                    by_id[pid] +>:Subagent:+> by_id[rec["id"]];
                }
            }
        }
        extras: list[str] = [];
        if "extra_parents" in rec {
            extras = rec["extra_parents"] as list[str];
        }
        for ep in extras {
            if ep in by_id {
                if rec["id"] in by_id {
                    by_id[ep] +>:Subagent:+> by_id[rec["id"]];
                }
            }
        }
    }
    return by_id;
}

def discover_roots(records: list[dict], exclude_archived: bool = True) -> list[str] {
    build_graph(records);
    roots: list[tuple[int, str]] = [];
    for rec in records {
        pid: str = "";
        if "parent_id" in rec {
            if rec["parent_id"] != None {
                pid = rec["parent_id"];
            }
        }
        if pid == "" {
            take: bool = True;
            if exclude_archived {
                arch: bool = False;
                if "archived" in rec {
                    arch = rec["archived"];
                }
                if arch {
                    take = False;
                }
            }
            if take {
                cr: int = 0;
                if "created" in rec {
                    cr = rec["created"];
                }
                roots.append((cr, rec["id"]));
            }
        }
    }
    roots.sort();
    roots.reverse();
    out: list[str] = [];
    for pair in roots {
        out.append(pair[1]);
    }
    return out;
}

def tree_session_ids(records: list[dict], root_id: str, exclude_archived: bool = True) -> list[str] {
    by_id = build_graph(records);
    if root_id not in by_id {
        return [];
    }
    start = by_id[root_id];
    w = start spawn TreeIds(exclude_archived=exclude_archived, claimed={}, acc=[]);
    found: list[str] = w.acc;
    found.sort();
    return found;
}

def remaining_cache_paths(cached_paths: list[str], discovered_ids: list[str], durable: bool) -> list[str] {
    if durable {
        out: list[str] = [];
        for p in cached_paths {
            out.append(p);
        }
        out.sort();
        return out;
    }
    disc: dict[str, bool] = {};
    for d in discovered_ids {
        disc[d] = True;
    }
    kept: list[str] = [];
    for p in cached_paths {
        if p in disc {
            kept.append(p);
        }
    }
    kept.sort();
    return kept;
}

def sum_tokens(records: list[dict], session_ids: list[str]) -> int {
    tok_by: dict[str, int] = {};
    for rec in records {
        t: int = 0;
        if "tokens" in rec {
            t = rec["tokens"];
        }
        tok_by[rec["id"]] = t;
    }
    total: int = 0;
    for sid in session_ids {
        if sid in tok_by {
            total = total + tok_by[sid];
        }
    }
    return total;
}

test "archived_roots_excluded_from_discovery" {
    recs: list[dict] = [
        {"id": "r1", "parent_id": None, "archived": False, "tokens": 100, "created": 2, "path_key": "p1"},
        {"id": "r2", "parent_id": None, "archived": True, "tokens": 50, "created": 1, "path_key": "p2"},
    ];
    disc = discover_roots(recs, exclude_archived=True);
    assert disc == ["r1"];
    kept = remaining_cache_paths(["p1", "p2"], disc, durable=False);
    assert kept == ["p1"];
    full = discover_roots(recs, exclude_archived=False);
    assert sorted(full) == ["r1", "r2"];
}

test "metrics_drop_after_archived_eviction" {
    recs: list[dict] = [
        {"id": "r1", "parent_id": None, "archived": False, "tokens": 100, "created": 1, "path_key": "p1"},
        {"id": "r2", "parent_id": None, "archived": True, "tokens": 50, "created": 2, "path_key": "p2"},
    ];
    buggy = discover_roots(recs, exclude_archived=True);
    assert sum_tokens(recs, buggy) == 100;
    fixed = discover_roots(recs, exclude_archived=False);
    assert sum_tokens(recs, fixed) == 150;
}

test "recursive_tree_skips_archived_child" {
    recs: list[dict] = [
        {"id": "p", "parent_id": None, "archived": False, "tokens": 0, "created": 1},
        {"id": "c", "parent_id": "p", "archived": True, "tokens": 40, "created": 2},
    ];
    bug_ids = tree_session_ids(recs, "p", exclude_archived=True);
    assert bug_ids == ["p"];
    fix_ids = tree_session_ids(recs, "p", exclude_archived=False);
    assert fix_ids == ["c", "p"];
}

test "diamond_revisit_collects_once" {
    recs: list[dict] = [
        {"id": "p", "parent_id": None, "archived": False, "tokens": 0, "created": 1},
        {"id": "a", "parent_id": "p", "archived": False, "tokens": 1, "created": 2},
        {"id": "b", "parent_id": "p", "archived": False, "tokens": 2, "created": 3},
        {"id": "d", "parent_id": "a", "archived": False, "tokens": 9, "created": 4, "extra_parents": ["b"]},
    ];
    ids = tree_session_ids(recs, "p", exclude_archived=False);
    assert ids == ["a", "b", "d", "p"];
    assert sum_tokens(recs, ids) == 12;
}

test "unknown_root_returns_empty_tree" {
    recs: list[dict] = [
        {"id": "x", "parent_id": None, "archived": False, "tokens": 7, "created": 1},
    ];
    assert tree_session_ids(recs, "missing", exclude_archived=False) == [];
}

test "durable_provider_skips_cache_eviction" {
    kept = remaining_cache_paths(["p1", "p2", "p3"], ["p1"], durable=True);
    assert kept == ["p1", "p2", "p3"];
}
