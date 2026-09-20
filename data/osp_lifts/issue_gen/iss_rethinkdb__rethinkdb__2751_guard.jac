"""rethinkdb/rethinkdb#2751 — Recursive queries populate a node tree."""

node NRec {
    has nid: int;
    has title: str = "";
}

edge PEdge {}

walker TreePop {
    has claimed: dict[int, bool] = {};
    has built: dict[int, dict] = {};

    can walk with NRec entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        ch_nodes: list[NRec] = [here ->:PEdge:->][?:NRec];
        id_buf: list[int] = [];
        for cn in ch_nodes {
            id_buf.append(cn.nid);
        }
        id_buf = sorted(id_buf);
        ordered: list[NRec] = [];
        for want in id_buf {
            for cn in ch_nodes {
                if cn.nid == want {
                    ordered.append(cn);
                }
            }
        }
        child_dicts: list[dict] = [];
        for cn in ordered {
            if cn.nid in self.built {
                child_dicts.append(self.built[cn.nid]);
            } else {
                wk = cn spawn TreePop(claimed=self.claimed, built=self.built);
                if cn.nid in self.built {
                    child_dicts.append(self.built[cn.nid]);
                }
            }
        }
        row: dict = {};
        row["id"] = here.nid;
        row["title"] = here.title;
        row["children"] = child_dicts;
        self.built[here.nid] = row;
        print("populated", here.nid);
    }
}

def make_store(rows: list, extra_links: list | None = None) -> dict {
    st: dict = {};
    st["rows"] = rows;
    links: list = [];
    if extra_links is not None {
        links = extra_links;
    }
    st["extra_links"] = links;
    return st;
}

def get_node(store: dict, node_id: int) -> dict | None {
    rows: list = store["rows"] as list;
    for raw in rows {
        r: dict = raw as dict;
        rid: int = r["id"] as int;
        if rid == node_id {
            return r;
        }
    }
    return None;
}

def children_of(store: dict, parent_id: int) -> list[int] {
    rows: list = store["rows"] as list;
    out: list[int] = [];
    for raw in rows {
        r: dict = raw as dict;
        pid = r["parentId"];
        if pid is not None {
            if (pid as int) == parent_id {
                out.append(r["id"] as int);
            }
        }
    }
    links: list = store["extra_links"] as list;
    for raw in links {
        lk: list = raw as list;
        par: int = lk[0] as int;
        ch: int = lk[1] as int;
        if par == parent_id {
            out.append(ch);
        }
    }
    out = sorted(out);
    return out;
}

def _materialize(store: dict) -> dict[int, NRec] {
    rows: list = store["rows"] as list;
    idx: dict[int, NRec] = {};
    for raw in rows {
        r: dict = raw as dict;
        nid: int = r["id"] as int;
        t: str = "";
        if "title" in r {
            t = r["title"] as str;
        }
        nd = NRec(nid=nid, title=t);
        root ++> nd;
        idx[nid] = nd;
    }
    for raw in rows {
        r: dict = raw as dict;
        pid = r["parentId"];
        if pid is not None {
            p: int = pid as int;
            c: int = r["id"] as int;
            if p in idx {
                if c in idx {
                    idx[p] +>:PEdge:+> idx[c];
                }
            }
        }
    }
    links: list = store["extra_links"] as list;
    for raw in links {
        lk: list = raw as list;
        p: int = lk[0] as int;
        c: int = lk[1] as int;
        if p in idx {
            if c in idx {
                idx[p] +>:PEdge:+> idx[c];
            }
        }
    }
    return idx;
}

def populate_tree(store: dict, node_id: int) -> dict | None {
    if get_node(store, node_id) is None {
        return None;
    }
    idx: dict[int, NRec] = _materialize(store);
    if node_id not in idx {
        return None;
    }
    start = idx[node_id];
    wk = start spawn TreePop(claimed={}, built={});
    if node_id in wk.built {
        return wk.built[node_id];
    }
    return None;
}

"""rethinkdb/rethinkdb#2751 — Recursive queries populate a node tree."""

node NRec {
    has nid: int;
    has title: str = "";
}

edge PEdge {}

walker TreePop {
    has claimed: dict[int, bool] = {};
    has built: dict[int, dict] = {};

    can walk with NRec entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        ch_nodes: list[NRec] = [here ->:PEdge:->][?:NRec];
        id_buf: list[int] = [];
        for cn in ch_nodes {
            id_buf.append(cn.nid);
        }
        id_buf = sorted(id_buf);
        ordered: list[NRec] = [];
        for want in id_buf {
            for cn in ch_nodes {
                if cn.nid == want {
                    ordered.append(cn);
                }
            }
        }
        child_dicts: list[dict] = [];
        for cn in ordered {
            if cn.nid in self.built {
                child_dicts.append(self.built[cn.nid]);
            } else {
                wk = cn spawn TreePop(claimed=self.claimed, built=self.built);
                if cn.nid in self.built {
                    child_dicts.append(self.built[cn.nid]);
                }
            }
        }
        row: dict = {};
        row["id"] = here.nid;
        row["title"] = here.title;
        row["children"] = child_dicts;
        self.built[here.nid] = row;
        print("populated", here.nid);
    }
}

def make_store(rows: list, extra_links: list | None = None) -> dict {
    st: dict = {};
    st["rows"] = rows;
    links: list = [];
    if extra_links is not None {
        links = extra_links;
    }
    st["extra_links"] = links;
    return st;
}

def get_node(store: dict, node_id: int) -> dict | None {
    rows: list = store["rows"] as list;
    for raw in rows {
        r: dict = raw as dict;
        rid: int = r["id"] as int;
        if rid == node_id {
            return r;
        }
    }
    return None;
}

def children_of(store: dict, parent_id: int) -> list[int] {
    rows: list = store["rows"] as list;
    out: list[int] = [];
    for raw in rows {
        r: dict = raw as dict;
        pid = r["parentId"];
        if pid is not None {
            if (pid as int) == parent_id {
                out.append(r["id"] as int);
            }
        }
    }
    links: list = store["extra_links"] as list;
    for raw in links {
        lk: list = raw as list;
        par: int = lk[0] as int;
        ch: int = lk[1] as int;
        if par == parent_id {
            out.append(ch);
        }
    }
    out = sorted(out);
    return out;
}

def _materialize(store: dict) -> dict[int, NRec] {
    rows: list = store["rows"] as list;
    idx: dict[int, NRec] = {};
    for raw in rows {
        r: dict = raw as dict;
        nid: int = r["id"] as int;
        t: str = "";
        if "title" in r {
            t = r["title"] as str;
        }
        nd = NRec(nid=nid, title=t);
        root ++> nd;
        idx[nid] = nd;
    }
    for raw in rows {
        r: dict = raw as dict;
        pid = r["parentId"];
        if pid is not None {
            p: int = pid as int;
            c: int = r["id"] as int;
            if p in idx {
                if c in idx {
                    idx[p] +>:PEdge:+> idx[c];
                }
            }
        }
    }
    links: list = store["extra_links"] as list;
    for raw in links {
        lk: list = raw as list;
        p: int = lk[0] as int;
        c: int = lk[1] as int;
        if p in idx {
            if c in idx {
                idx[p] +>:PEdge:+> idx[c];
            }
        }
    }
    return idx;
}

def populate_tree(store: dict, node_id: int) -> dict | None {
    if get_node(store, node_id) is None {
        return None;
    }
    idx: dict[int, NRec] = _materialize(store);
    if node_id not in idx {
        return None;
    }
    start = idx[node_id];
    wk = start spawn TreePop(claimed={}, built={});
    if node_id in wk.built {
        return wk.built[node_id];
    }
    return None;
}

test "unknown_returns_none" {
    rows: list = [{"id": 1, "parentId": None, "title": "solo"}];
    st = make_store(rows);
    assert populate_tree(st, 99) is None;
    assert get_node(st, 99) is None;
}

test "leaf_empty_children" {
    rows: list = [{"id": 10, "parentId": None, "title": "leaf"}];
    st = make_store(rows);
    tree = populate_tree(st, 10);
    assert tree is not None;
    assert tree["id"] == 10;
    assert tree["title"] == "leaf";
    ch: list = tree["children"] as list;
    assert len(ch) == 0;
}

test "children_of_sorted" {
    rows: list = [
        {"id": 1, "parentId": None, "title": "root"},
        {"id": 3, "parentId": 1, "title": "c"},
        {"id": 2, "parentId": 1, "title": "b"},
    ];
    st = make_store(rows);
    got = children_of(st, 1);
    expect: list[int] = [2, 3];
    assert got == expect;
}

test "populate_nested" {
    rows: list = [
        {"id": 1, "parentId": None, "title": "root"},
        {"id": 2, "parentId": 1, "title": "a"},
        {"id": 3, "parentId": 1, "title": "b"},
        {"id": 4, "parentId": 2, "title": "c"},
    ];
    st = make_store(rows);
    tree = populate_tree(st, 1);
    assert tree is not None;
    assert tree["id"] == 1;
    top: list = tree["children"] as list;
    assert len(top) == 2;
    top_ids: list[int] = [];
    for raw in top {
        r: dict = raw as dict;
        top_ids.append(r["id"] as int);
    }
    top_ids = sorted(top_ids);
    expect_top: list[int] = [2, 3];
    assert top_ids == expect_top;
    first: dict = top[0] as dict;
    if (first["id"] as int) != 2 {
        first = top[1] as dict;
    }
    assert first["id"] == 2;
    sub: list = first["children"] as list;
    assert len(sub) == 1;
    leaf: dict = sub[0] as dict;
    assert leaf["id"] == 4;
    leaf_ch: list = leaf["children"] as list;
    assert len(leaf_ch) == 0;
}

test "cycle_extra_link_skips_revisit" {
    rows: list = [
        {"id": 1, "parentId": None, "title": "a"},
        {"id": 2, "parentId": 1, "title": "b"},
    ];
    extra: list = [[2, 1]];
    st = make_store(rows, extra);
    tree = populate_tree(st, 1);
    assert tree is not None;
    assert tree["id"] == 1;
    ch: list = tree["children"] as list;
    assert len(ch) == 1;
    kid: dict = ch[0] as dict;
    assert kid["id"] == 2;
    kid_ch: list = kid["children"] as list;
    assert len(kid_ch) == 0;
}
