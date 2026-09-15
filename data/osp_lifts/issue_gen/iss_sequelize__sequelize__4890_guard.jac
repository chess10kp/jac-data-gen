"""sequelize/sequelize#4890 — recursive CTE row expansion over parent-child graphs."""

node Row {
    has rid: str;
    has label: str = "";
}

node StoreHub {
    has rows: dict[str, Row] = {};
}

edge ParentOf {}

walker CteWalker {
    has cte_name: str = "cte";
    has initial_ids: list[str] = [];
    has claimed: dict[str, bool] = {};
    has result: list[str] = [];

    can bootstrap with StoreHub entry {
        seeds: list[Row] = [];
        for rid in sorted(self.initial_ids) {
            if rid in here.rows {
                seeds.append(here.rows[rid]);
            }
        }
        if seeds {
            visit seeds;
        } else {
            print(self.result);
            disengage;
        }
    }

    can expand with Row entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        self.result.append(here.rid);
        kids: list[Row] = [];
        for kid in [here ->:ParentOf:->][?:Row] {
            kids.append(kid);
        }
        pending: list[Row] = sort_rows_by_rid(kids);
        next_visit: list[Row] = [];
        for kid in pending {
            if kid.rid not in self.claimed {
                next_visit.append(kid);
            }
        }
        if next_visit {
            visit next_visit;
        }
        print(self.result);
    }
}

def sort_rows_by_rid(rows: list[Row]) -> list[Row] {
    out: list[Row] = [];
    for r in rows {
        out.append(r);
    }
    i = 0;
    while i < len(out) {
        j = i + 1;
        while j < len(out) {
            if out[j].rid < out[i].rid {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def make_store() -> StoreHub {
    hub = StoreHub(rows={});
    root ++> hub;
    return hub;
}

def add_row(hub: StoreHub, rid: str, label: str = "") -> str {
    if rid in hub.rows {
        return rid;
    }
    row = Row(rid=rid, label=label);
    hub ++> row;
    hub.rows[rid] = row;
    return rid;
}

def link_child(hub: StoreHub, parent_rid: str, child_rid: str) -> bool {
    if parent_rid not in hub.rows {
        return False;
    }
    if child_rid not in hub.rows {
        return False;
    }
    parent = hub.rows[parent_rid];
    child = hub.rows[child_rid];
    parent +>:ParentOf:+> child;
    return True;
}

def recursive_cte_collect(hub: StoreHub, initial_ids: list[str], cte_name: str = "cte") -> list[str] {
    ids_copy: list[str] = [];
    for x in initial_ids {
        ids_copy.append(x);
    }
    w = hub spawn CteWalker(
        cte_name=cte_name,
        initial_ids=ids_copy,
        claimed={},
        result=[]
    );
    return w.result;
}

def filter_known_ids(hub: StoreHub, ids: list[str]) -> list[str] {
    out: list[str] = [];
    for rid in sorted(ids) {
        if rid in hub.rows {
            out.append(rid);
        }
    }
    return out;
}

def cte_row_labels(hub: StoreHub, initial_ids: list[str], cte_name: str = "cte") -> list[str] {
    order = recursive_cte_collect(hub, initial_ids, cte_name);
    labels: list[str] = [];
    for rid in order {
        labels.append(hub.rows[rid].label);
    }
    return labels;
}

test "linear_chain_collect" {
    hub = make_store();
    add_row(hub, "a", "A");
    add_row(hub, "b", "B");
    add_row(hub, "c", "C");
    link_child(hub, "a", "b");
    link_child(hub, "b", "c");
    got = recursive_cte_collect(hub, ["a"]);
    assert (got == ["a", "b", "c"]);
}

test "cycle_claim_skip" {
    hub = make_store();
    add_row(hub, "a", "");
    add_row(hub, "b", "");
    link_child(hub, "a", "b");
    link_child(hub, "b", "a");
    got = recursive_cte_collect(hub, ["a"]);
    assert (got == ["a", "b"]);
}

test "diamond_sorted_children" {
    hub = make_store();
    add_row(hub, "root", "");
    add_row(hub, "b", "");
    add_row(hub, "c", "");
    add_row(hub, "d", "");
    link_child(hub, "root", "c");
    link_child(hub, "root", "b");
    link_child(hub, "b", "d");
    link_child(hub, "c", "d");
    got = recursive_cte_collect(hub, ["root"]);
    assert (got == ["root", "b", "c", "d"]);
}

test "filter_known_ids_sorted" {
    hub = make_store();
    add_row(hub, "x", "");
    add_row(hub, "y", "");
    got = filter_known_ids(hub, ["y", "missing", "x"]);
    assert (got == ["x", "y"]);
}

test "cte_row_labels_follow_collect" {
    hub = make_store();
    add_row(hub, "p", "Parent");
    add_row(hub, "q", "Child");
    link_child(hub, "p", "q");
    got = cte_row_labels(hub, ["p"]);
    assert (got == ["Parent", "Child"]);
}

test "unknown_seed_yields_empty" {
    hub = make_store();
    add_row(hub, "only", "");
    got = recursive_cte_collect(hub, ["nope"]);
    assert (got == []);
}
