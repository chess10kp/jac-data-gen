"""payloadcms/payload#17457 — nested-docs resaveChildren silent rollback on child validation."""

node Page {
    has cid: str;
    has title: str;
    has updated_at: int = 0;
    has requires_upload: bool = False;
    has upload_ok: bool = True;
}

edge ChildOf {}

node Store {
    has by_id: dict[str, Page] = {};
}

walker DescCollect {
    has claimed: dict[str, bool] = {};
    has origin: str = "";
    has ordered: list[str] = [];

    can launch with Store entry {
        print("desc_collect_launch");
        root spawn DescCollect(claimed={}, origin=self.origin, ordered=[]);
        if self.origin in here.by_id {
            visit [here.by_id[self.origin]];
        } else {
            disengage;
        }
    }

    can step with Page entry {
        print("desc_collect_step");
        root spawn DescCollect(claimed={}, origin=self.origin, ordered=[]);
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid != self.origin {
            self.ordered.append(here.cid);
        }
        kids: list[Page] = [];
        for ch in [here ->:ChildOf:->][?:Page] {
            kids.append(ch);
        }
        cids: list[str] = [];
        for kid in kids {
            cids.append(kid.cid);
        }
        cids.sort();
        visit_kids: list[Page] = [];
        for cid in cids {
            for kid in kids {
                if kid.cid == cid {
                    visit_kids.append(kid);
                }
            }
        }
        if visit_kids {
            visit :0: visit_kids;
        } else {
            disengage;
        }
    }
}

def build_store(rows: list[dict]) -> Store {
    st = Store();
    for row in rows {
        pid = row["id"] as str;
        pg = Page(
            cid=pid,
            title=row["title"] as str,
            updated_at=row["updated_at"] as int,
            requires_upload=row["requires_upload"] as bool,
            upload_ok=row["upload_ok"] as bool
        );
        st.by_id[pid] = pg;
    }
    for row in rows {
        par_id = row["parent"] as str;
        if par_id != "" {
            par = st.by_id[par_id];
            ch = st.by_id[row["id"] as str];
            par +>:ChildOf:+> ch;
        }
    }
    return st;
}

def collect_descendant_ids(st: Store, origin: str) -> list[str] {
    if origin not in st.by_id {
        return [];
    }
    wk = st spawn DescCollect(claimed={}, origin=origin, ordered=[]);
    out = wk.ordered;
    out.sort();
    return out;
}

def validation_errors(st: Store, page_id: str) -> list[str] {
    errs: list[str] = [];
    if page_id not in st.by_id {
        return errs;
    }
    pg = st.by_id[page_id];
    if pg.requires_upload and not pg.upload_ok {
        msg = "invalid upload: " + page_id;
        errs.append(msg);
    }
    return errs;
}

def snapshot_store(st: Store) -> dict[str, dict[str, object]] {
    snap: dict[str, dict[str, object]] = {};
    ids: list[str] = [];
    for pid in st.by_id {
        ids.append(pid);
    }
    ids.sort();
    for pid in ids {
        pg = st.by_id[pid];
        row: dict[str, object] = {};
        row["title"] = pg.title;
        row["updated_at"] = pg.updated_at;
        row["requires_upload"] = pg.requires_upload;
        row["upload_ok"] = pg.upload_ok;
        snap[pid] = row;
    }
    return snap;
}

def restore_store(st: Store, snap: dict[str, dict[str, object]]) {
    for pid in snap {
        pg = st.by_id[pid];
        row = snap[pid] as dict[str, object];
        pg.title = row["title"] as str;
        pg.updated_at = row["updated_at"] as int;
        pg.requires_upload = row["requires_upload"] as bool;
        pg.upload_ok = row["upload_ok"] as bool;
    }
}

def read_page(st: Store, page_id: str) -> dict[str, object] | None {
    if page_id not in st.by_id {
        return None;
    }
    pg = st.by_id[page_id];
    out: dict[str, object] = {};
    out["id"] = pg.cid;
    out["title"] = pg.title;
    out["updated_at"] = pg.updated_at;
    out["requires_upload"] = pg.requires_upload;
    out["upload_ok"] = pg.upload_ok;
    return out;
}

def update_parent(
    st: Store,
    parent_id: str,
    patch: dict[str, str],
    loud_fail: bool = False
) -> dict[str, object] {
    empty: dict[str, object] = {};
    empty["ok"] = False;
    empty["updated_at"] = 0;
    empty["persisted"] = False;
    empty["logged_errors"] = [];
    if parent_id not in st.by_id {
        return empty;
    }
    snap = snapshot_store(st);
    parent = st.by_id[parent_id];
    if "title" in patch {
        parent.title = patch["title"] as str;
    }
    parent.updated_at = parent.updated_at + 1;
    response_at = parent.updated_at;
    desc_ids = collect_descendant_ids(st, parent_id);
    logged: list[str] = [];
    for did in desc_ids {
        errs = validation_errors(st, did);
        if len(errs) > 0 {
            for e in errs {
                logged.append(e);
            }
        } else {
            child = st.by_id[did];
            child.updated_at = child.updated_at + 1;
        }
    }
    logged.sort();
    if len(logged) > 0 {
        restore_store(st, snap);
        res: dict[str, object] = {};
        if loud_fail {
            res["ok"] = False;
            res["updated_at"] = response_at;
            res["persisted"] = False;
            res["logged_errors"] = logged;
            return res;
        }
        res["ok"] = True;
        res["updated_at"] = response_at;
        res["persisted"] = False;
        res["logged_errors"] = logged;
        return res;
    }
    ok_res: dict[str, object] = {};
    ok_res["ok"] = True;
    ok_res["updated_at"] = response_at;
    ok_res["persisted"] = True;
    ok_res["logged_errors"] = [];
    return ok_res;
}
