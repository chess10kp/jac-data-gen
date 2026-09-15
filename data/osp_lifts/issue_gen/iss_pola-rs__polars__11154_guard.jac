"""pola-rs/polars#11154 — recursive CTE growth chain (OSP lift)."""

node CTERow {
    has cid: str;
    has index: int;
    has value: float;
}

edge Link {}
edge Recurse {}

walker GrowthWalker {
    has claimed: dict[str, bool] = {};
    has growth_rate: float = 1.08;
    has max_index: int = 10;
    has rows: list[tuple[int, float]] = [];

    can extend with CTERow entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.rows.append((here.index, here.value));
        print("growth cte index=", here.index, " value=", here.value);
        if here.index >= self.max_index {
            disengage;
        }
        nxt_idx: int = here.index + 1;
        nxt_val: float = here.value * self.growth_rate;
        nxt_cid: str = "r" + str(nxt_idx);
        child = CTERow(cid=nxt_cid, index=nxt_idx, value=nxt_val);
        here +>: Recurse :+> child;
        visit :0: [child];
    }
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has rows: list[tuple[int, float]] = [];

    can begin with Root entry {
        print("collect begin at root");
        fronts: list[CTERow] = [here ->: Link :->][?:CTERow];
        if fronts {
            visit :0: fronts;
        } else {
            disengage;
        }
    }

    can gather with CTERow entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.rows.append((here.index, here.value));
        print("collect cid=", here.cid, " index=", here.index);
        kids: list[CTERow] = [here ->: Recurse :->][?:CTERow];
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def run_growth_cte(
    initial_value: float, growth_rate: float, max_index: int
) -> list[tuple[int, float]] {
    base = CTERow(cid="r1", index=1, value=initial_value);
    root +>: Link :+> base;
    w = base spawn GrowthWalker(
        claimed={}, growth_rate=growth_rate, max_index=max_index, rows=[]
    );
    out: list[tuple[int, float]] = sorted(w.rows);
    return out;
}

def lookup_cte_row(
    rows: list[tuple[int, float]], index: int
) -> tuple[int, float] | None {
    for pair in rows {
        if pair[0] == index {
            return pair;
        }
    }
    return None;
}

def supports_recursive_cte -> bool {
    return True;
}

def collect_cte_rows(start: CTERow) -> list[tuple[int, float]] {
    w = start spawn CollectWalker(claimed={}, rows=[]);
    out: list[tuple[int, float]] = sorted(w.rows);
    return out;
}

with entry {
    demo_base = CTERow(cid="demo_r1", index=1, value=100.0);
    root +>: Link :+> demo_base;
    demo_w = demo_base spawn GrowthWalker(
        claimed={}, growth_rate=1.08, max_index=10, rows=[]
    );
    print("demo growth rows=", len(demo_w.rows));
    root spawn CollectWalker(claimed={}, rows=[]);
}

test "supports_recursive_cte" {
    assert supports_recursive_cte() == True;
}

test "run_growth_cte_rows" {
    rows = run_growth_cte(10.0, 2.0, 3);
    assert len(rows) == 3;
    assert rows == [(1, 10.0), (2, 20.0), (3, 40.0)];
}

test "lookup_cte_row_hit" {
    rows = run_growth_cte(10.0, 2.0, 3);
    hit = lookup_cte_row(rows, 2);
    assert hit == (2, 20.0);
}

test "lookup_cte_row_miss" {
    rows = run_growth_cte(10.0, 2.0, 3);
    miss = lookup_cte_row(rows, 99);
    assert miss is None;
}

test "collect_cte_rows_chain" {
    base = CTERow(cid="t1", index=1, value=5.0);
    c2 = CTERow(cid="t2", index=2, value=10.0);
    c3 = CTERow(cid="t3", index=3, value=20.0);
    base +>: Recurse :+> c2;
    c2 +>: Recurse :+> c3;
    got = collect_cte_rows(base);
    assert got == [(1, 5.0), (2, 10.0), (3, 20.0)];
}

test "run_growth_cte_rate" {
    rows = run_growth_cte(100.0, 1.08, 2);
    assert rows == [(1, 100.0), (2, 108.0)];
}
