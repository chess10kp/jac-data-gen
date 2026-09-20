"""
CherryHQ/cherry-studio#16994 — Topic/Session pagination, grouping, refresh semantics.
"""

node Owner {
    has oid: str;
}

node Record {
    has rid: str;
    has gid: str;
    has stamp: int = 0;
}

node Page {
    has cursor: str;
    has stamp: int = 0;
    has valid: bool = True;
}

edge Owns {}
edge Next {}
edge OnPage {}

walker RecordCollect {
    has claimed: dict[str, bool] = {};
    has owner_id: str = "";
    has group_filter: str = "";
    has found: list[str] = [];

    can touch_owner with Owner entry {
        if here.oid != self.owner_id {
            disengage;
        }
        if here.oid in self.claimed {
            skip;
        }
        self.claimed[here.oid] = True;
        kids: list[object] = [];
        for pg in [here ->:Owns:->][?:Page] {
            kids.append(pg);
        }
        visit :0: kids else {
            disengage;
        }
    }

    can touch_page with Page entry {
        if here.cursor in self.claimed {
            skip;
        }
        self.claimed[here.cursor] = True;
        if not here.valid {
            disengage;
        }
        print("page", here.cursor);
        kids: list[object] = [];
        for rec in [here ->:OnPage:->][?:Record] {
            kids.append(rec);
        }
        for nxt in [here ->:Next:->][?:Page] {
            kids.append(nxt);
        }
        visit :0: kids else {
            disengage;
        }
    }

    can touch_record with Record entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        if self.group_filter != "" and here.gid != self.group_filter {
            disengage;
        }
        print("record", here.rid);
        self.found.append(here.rid);
        disengage;
    }
}

walker CascadeCollect {
    has claimed: dict[str, bool] = {};
    has write_stamp: int = 0;
    has targets: list[str] = [];
    has pages: list[Page] = [];

    can step_page with Page entry {
        if here.cursor in self.claimed {
            skip;
        }
        self.claimed[here.cursor] = True;
        self.pages.append(here);
        if here.stamp <= self.write_stamp {
            self.targets.append(here.cursor);
        }
        print("cascade", here.cursor);
        kids: list[object] = [];
        for nxt in [here ->:Next:->][?:Page] {
            kids.append(nxt);
        }
        visit :0: kids else {
            disengage;
        }
    }
}

def _find_owner(graph_root: Owner, owner_id: str) -> Owner | None {
    if graph_root.oid == owner_id {
        return graph_root;
    }
    for ch in [graph_root ->:Owns:->][?:Owner] {
        hit = _find_owner(ch, owner_id);
        if hit {
            return hit;
        }
    }
    return None;
}

def list_record_ids(owner_id: str, graph_root: Owner) -> list[str] {
    own = _find_owner(graph_root, owner_id);
    if not own {
        return [];
    }
    w = own spawn RecordCollect(owner_id=owner_id, group_filter="");
    return sorted(w.found);
}

def grouped_record_ids(owner_id: str, group_id: str, graph_root: Owner) -> list[str] {
    own = _find_owner(graph_root, owner_id);
    if not own {
        return [];
    }
    w = own spawn RecordCollect(owner_id=owner_id, group_filter=group_id);
    return sorted(w.found);
}

def invalidate_from_write(owner_id: str, write_stamp: int, graph_root: Owner) -> list[str] {
    own = _find_owner(graph_root, owner_id);
    if not own {
        return [];
    }
    heads: list[Page] = [];
    for pg in [own ->:Owns:->][?:Page] {
        heads.append(pg);
    }
    tokens: list[str] = [];
    touched: list[Page] = [];
    for head in heads {
        w = head spawn CascadeCollect(write_stamp=write_stamp);
        for tok in w.targets {
            tokens.append(tok);
        }
        for pg in w.pages {
            touched.append(pg);
        }
    }
    stale: dict[str, bool] = {};
    for tok in tokens {
        stale[tok] = True;
    }
    for pg in touched {
        if pg.cursor in stale {
            pg.valid = False;
        }
    }
    uniq: list[str] = [];
    seen: dict[str, bool] = {};
    for tok in tokens {
        if tok not in seen {
            seen[tok] = True;
            uniq.append(tok);
        }
    }
    return sorted(uniq);
}

def refresh_head_cursor(owner_id: str, graph_root: Owner) -> str {
    own = _find_owner(graph_root, owner_id);
    if not own {
        return "";
    }
    for pg in [own ->:Owns:->][?:Page] {
        return pg.cursor;
    }
    return "";
}

def page_has_next(owner_id: str, cursor: str, graph_root: Owner) -> bool {
    own = _find_owner(graph_root, owner_id);
    if not own {
        return False;
    }
    for pg in [own ->:Owns:->][?:Page] {
        if pg.cursor == cursor {
            nxt_list: list[Page] = [];
            for nx in [pg ->:Next:->][?:Page] {
                nxt_list.append(nx);
            }
            return len(nxt_list) > 0;
        }
        cur = pg;
        guard: dict[str, bool] = {};
        while cur {
            if cur.cursor in guard {
                break;
            }
            guard[cur.cursor] = True;
            if cur.cursor == cursor {
                nxt_list2: list[Page] = [];
                for nx in [cur ->:Next:->][?:Page] {
                    nxt_list2.append(nx);
                }
                return len(nxt_list2) > 0;
            }
            nxt: Page | None = None;
            for nx in [cur ->:Next:->][?:Page] {
                nxt = nx;
                break;
            }
            cur = nxt;
        }
    }
    return False;
}

test "list_record_ids_basic" {
    own = Owner(oid="alice");
    p0 = Page(cursor="p0");
    r1 = Record(rid="a", gid="t");
    r2 = Record(rid="b", gid="t");
    own +>:Owns:+> p0;
    p0 +>:OnPage:+> r1;
    p0 +>:OnPage:+> r2;
    got = list_record_ids("alice", own);
    assert got == ["a", "b"];
}

test "grouped_record_ids_filter" {
    own = Owner(oid="bob");
    p0 = Page(cursor="p0");
    r1 = Record(rid="x", gid="g1");
    r2 = Record(rid="y", gid="g2");
    own +>:Owns:+> p0;
    p0 +>:OnPage:+> r1;
    p0 +>:OnPage:+> r2;
    got = grouped_record_ids("bob", "g1", own);
    assert got == ["x"];
}

test "invalidate_from_write_marks_stale" {
    own = Owner(oid="carol");
    p0 = Page(cursor="c0", stamp=1, valid=True);
    p1 = Page(cursor="c1", stamp=5, valid=True);
    p0 +>:Next:+> p1;
    own +>:Owns:+> p0;
    stale = invalidate_from_write("carol", 3, own);
    assert stale == ["c0"];
    assert p0.valid == False;
    assert p1.valid == True;
}

test "refresh_head_cursor_first" {
    own = Owner(oid="dave");
    p0 = Page(cursor="head0");
    own +>:Owns:+> p0;
    got = refresh_head_cursor("dave", own);
    assert got == "head0";
}

test "page_has_next_true" {
    own = Owner(oid="eve");
    p0 = Page(cursor="a");
    p1 = Page(cursor="b");
    p0 +>:Next:+> p1;
    own +>:Owns:+> p0;
    assert page_has_next("eve", "a", own) == True;
}

test "page_has_next_false" {
    own = Owner(oid="frank");
    p0 = Page(cursor="only");
    own +>:Owns:+> p0;
    assert page_has_next("frank", "only", own) == False;
}
