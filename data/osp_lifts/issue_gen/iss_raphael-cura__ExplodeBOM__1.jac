"""raphael-cura/ExplodeBOM#1 — BOM explosion lifted from deque BFS with cycle guard."""

glob DEFAULT_MAX_DEPTH = 50;
glob DEFAULT_MAX_ITER = 20;
glob DEFAULT_TOL = 0.000000001;

class BOMExplosionError(Exception) {
    has msg: str = "";
}

node material {
    has mid: int;
    has branch: str = "";
    has per_qty: float = 1.0;
    has is_intermediate: bool = False;
}

edge requires {}

node bom_store {
    has by_id: dict[int, material] = {};
    has root_ids: list[int] = [];
    has child_ids: dict[int, bool] = {};
}

walker explode_w {
    has claimed: dict[str, bool] = {};
    has rows: list[dict] = [];
    has root_mid: int = 0;
    has cum_qty: float = 1.0;
    has depth: int = 0;
    has max_depth: int = 50;
    has branch_filter: str = "";

    can walk with material entry {
        if self.branch_filter != "" and here.branch != self.branch_filter {
            disengage;
        }
        ck: str = str(here.mid);
        if ck in self.claimed {
            skip;
        }
        child_claimed: dict[str, bool] = {};
        for pk in self.claimed {
            if self.claimed[pk] {
                child_claimed[pk] = True;
            }
        }
        child_claimed[ck] = True;
        if self.depth > 0 {
            rr: dict[str, int | float | str] = {};
            rr["root_id"] = self.root_mid;
            rr["component_id"] = here.mid;
            rr["level"] = self.depth;
            rr["qty"] = self.cum_qty;
            rr["branch"] = here.branch;
            self.rows.append(rr);
        }
        if self.depth >= self.max_depth {
            disengage;
        }
        kids: list[material] = [here ->:requires:->][?:material];
        if len(kids) == 0 {
            disengage;
        }
        i: int = 0;
        while i < len(kids) {
            kid = kids[i];
            nqty: float = self.cum_qty * kid.per_qty;
            kid spawn explode_w(
                claimed=child_claimed,
                rows=self.rows,
                root_mid=self.root_mid,
                cum_qty=nqty,
                depth=self.depth + 1,
                max_depth=self.max_depth,
                branch_filter=self.branch_filter
            );
            print("walk mid=" + str(here.mid) + " child=" + str(kid.mid) + " depth=" + str(self.depth));
            i = i + 1;
        }
    }
}

def build_bom_store(bom_rows: list[dict]) -> bom_store {
    bs = bom_store();
    parents: dict[int, bool] = {};
    i: int = 0;
    while i < len(bom_rows) {
        row = bom_rows[i];
        pid: int = row["parent_id"];
        cid: int = row["child_id"];
        parents[pid] = True;
        bs.child_ids[cid] = True;
        if pid not in bs.by_id {
            pnd = material(mid=pid, branch=row["branch"]);
            bs.by_id[pid] = pnd;
        }
        i = i + 1;
    }
    i = 0;
    while i < len(bom_rows) {
        row = bom_rows[i];
        pid = row["parent_id"];
        cid = row["child_id"];
        if pid not in bs.by_id {
            raise BOMExplosionError("unknown parent id");
        }
        parent = bs.by_id[pid];
        cnd = material(
            mid=cid,
            branch=row["branch"],
            per_qty=row["qty"],
            is_intermediate=cid in parents
        );
        parent +>:requires:+> cnd;
        i = i + 1;
    }
    for mid in bs.by_id {
        if mid not in bs.child_ids {
            bs.root_ids.append(mid);
        }
    }
    return bs;
}

def resolve_roots(requested: list[int] | None, bs: bom_store) -> list[int] {
    if requested is None {
        return bs.root_ids;
    }
    out: list[int] = [];
    i: int = 0;
    while i < len(requested) {
        rid = requested[i];
        if rid in bs.by_id {
            out.append(rid);
        }
        i = i + 1;
    }
    return out;
}

def aggregate_rows(rows: list[dict], tol: float) -> list[dict] {
    acc: dict[str, dict] = {};
    i: int = 0;
    while i < len(rows) {
        row = rows[i];
        k: str = (
            str(row["root_id"]) + "|"
            + str(row["component_id"]) + "|"
            + row["branch"] + "|"
            + str(row["level"])
        );
        qty_val: float = row["qty"];
        if abs(qty_val) < tol {
            qty_val = 0.0;
        }
        if k not in acc {
            nr: dict[str, int | float | str] = {};
            nr["root_id"] = row["root_id"];
            nr["component_id"] = row["component_id"];
            nr["level"] = row["level"];
            nr["qty"] = qty_val;
            nr["branch"] = row["branch"];
            acc[k] = nr;
        } else {
            acc[k]["qty"] = acc[k]["qty"] + qty_val;
        }
        i = i + 1;
    }
    out: list[dict] = [];
    for k in acc {
        out.append(acc[k]);
    }
    return out;
}

def rows_stable(before: list[dict], after: list[dict], tol: float) -> bool {
    if len(before) != len(after) {
        return False;
    }
    i: int = 0;
    while i < len(before) {
        if abs(before[i]["qty"] - after[i]["qty"]) > tol {
            return False;
        }
        i = i + 1;
    }
    return True;
}

def rebalance_rows(rows: list[dict], max_iter: int, tol: float) -> list[dict] {
    cur: list[dict] = rows;
    it: int = 0;
    while it < max_iter {
        nxt = aggregate_rows(cur, tol);
        if rows_stable(cur, nxt, tol) {
            return nxt;
        }
        cur = nxt;
        it = it + 1;
    }
    return cur;
}

def split_intermediates(rows: list[dict], bs: bom_store) -> list[dict] {
    out: list[dict] = [];
    i: int = 0;
    while i < len(rows) {
        row = rows[i];
        cid: int = row["component_id"];
        if cid in bs.by_id and bs.by_id[cid].is_intermediate {
            row["kind"] = "intermediate";
        } else {
            row["kind"] = "basic";
        }
        out.append(row);
        i = i + 1;
    }
    return out;
}

def sort_rows(rows: list[dict]) -> list[dict] {
    keys: list[str] = [];
    i: int = 0;
    while i < len(rows) {
        row = rows[i];
        keys.append(
            str(row["root_id"]) + "|"
            + str(row["component_id"]) + "|"
            + row["branch"] + "|"
            + str(row["level"]) + "|"
            + str(row["qty"])
        );
        i = i + 1;
    }
    keys = sorted(keys);
    out: list[dict] = [];
    i = 0;
    while i < len(keys) {
        k = keys[i];
        j: int = 0;
        while j < len(rows) {
            row = rows[j];
            rk: str = (
                str(row["root_id"]) + "|"
                + str(row["component_id"]) + "|"
                + row["branch"] + "|"
                + str(row["level"]) + "|"
                + str(row["qty"])
            );
            if rk == k {
                out.append(row);
            }
            j = j + 1;
        }
        i = i + 1;
    }
    return out;
}

def explode_bom(
    bom_rows: list[dict],
    key_colfilial: str | None = None,
    root_ids: list[int] | None = None,
    max_depth: int = DEFAULT_MAX_DEPTH,
    max_iter: int = DEFAULT_MAX_ITER,
    tol: float = DEFAULT_TOL,
    tag_intermediates: bool = True,
) -> list[dict] {
    bs = build_bom_store(bom_rows);
    roots = resolve_roots(root_ids, bs);
    all_rows: list[dict] = [];
    ri: int = 0;
    while ri < len(roots) {
        rid = roots[ri];
        if rid not in bs.by_id {
            ri = ri + 1;
            continue;
        }
        root_nd = bs.by_id[rid];
        rows_acc: list[dict] = [];
        branch_f: str = "";
        if key_colfilial is not None {
            branch_f = key_colfilial;
        }
        root_nd spawn explode_w(
            claimed={},
            rows=rows_acc,
            root_mid=rid,
            cum_qty=1.0,
            depth=0,
            max_depth=max_depth,
            branch_filter=branch_f
        );
        print("explode root=" + str(rid) + " rows=" + str(len(rows_acc)));
        merged = rebalance_rows(rows_acc, max_iter, tol);
        mi: int = 0;
        while mi < len(merged) {
            all_rows.append(merged[mi]);
            mi = mi + 1;
        }
        ri = ri + 1;
    }
    if tag_intermediates {
        all_rows = split_intermediates(all_rows, bs);
    }
    return sort_rows(all_rows);
}
