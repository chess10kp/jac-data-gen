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
