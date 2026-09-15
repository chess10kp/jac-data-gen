"""trinodb/trino#19278 - Failure for table function parameter in recursive query."""

edge next_row {}

node CteRow {
    has n: int;
    has m: int;
    has rid: str;
}

walker ExpandCte {
    has claimed: dict[str, bool] = {};
    has threshold: int = 5;
    has rows: list[list[int]] = [];

    can step with CteRow entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        row_pair: list[int] = [here.n, here.m];
        self.rows.append(row_pair);
        print(here.n, here.m);
        next_n = here.n + 1;
        if next_n < self.threshold {
            bound_m = bind_recursive_param(here.n);
            kid = CteRow(n=next_n, m=bound_m, rid="n_" + str(next_n));
            here +>:next_row:+> kid;
            visit :0: [kid];
        } else {
            disengage;
        }
    }
}

def sequence(stop: int) -> list[int] {
    out: list[int] = [];
    if stop < 1 {
        return out;
    }
    v = 1;
    while v <= stop {
        out.append(v);
        v += 1;
    }
    return out;
}

def max_from_table(stop_param: int) -> int {
    vals = sequence(stop_param);
    if len(vals) == 0 {
        return 0;
    }
    best = vals[0];
    for x in vals {
        if x > best {
            best = x;
        }
    }
    return best;
}

def bind_recursive_param(n: int) -> int {
    # TABLE(sequence(stop => n+1)) then max(sequential_number)
    stop_expr = n + 1;
    return max_from_table(stop_expr);
}

def eval_recursive_t(threshold: int = 5) -> list[list[int]] {
    seed = CteRow(n=1, m=0, rid="n_1");
    root ++> seed;
    w = seed spawn ExpandCte(threshold=threshold);
    return w.rows;
}

def lookup_row_by_rid(rid: str, threshold: int = 5) -> list[int] | None {
    if rid == "" {
        return None;
    }
    all_rows = eval_recursive_t(threshold);
    for row in all_rows {
        row_rid = "n_" + str(row[0]);
        if row_rid == rid {
            return row;
        }
    }
    return None;
}

test "recursive_cte_table_fn_binding" {
    got = eval_recursive_t(5);
    want: list[list[int]] = [[1, 0], [2, 2], [3, 3], [4, 4]];
    assert sorted(got) == sorted(want);
}

test "bind_recursive_param_resolves_outer_n" {
    assert bind_recursive_param(1) == 2;
    assert bind_recursive_param(2) == 3;
    assert bind_recursive_param(3) == 4;
}

test "sequence_empty_stop" {
    assert sequence(0) == [];
    assert max_from_table(0) == 0;
}

test "diamond_revisit_claim_skip" {
    n1 = CteRow(n=1, m=0, rid="n_1");
    n2 = CteRow(n=2, m=2, rid="n_2");
    n3 = CteRow(n=3, m=3, rid="n_3");
    n4 = CteRow(n=4, m=4, rid="n_4");
    root ++> n1;
    n1 +>:next_row:+> n2;
    n1 +>:next_row:+> n3;
    n2 +>:next_row:+> n4;
    n3 +>:next_row:+> n4;
    w = n1 spawn ExpandCte(threshold=5);
    fours: list[list[int]] = [];
    for r in w.rows {
        if r[0] == 4 {
            fours.append(r);
        }
    }
    assert len(fours) == 1;
}

test "lookup_unknown_rid" {
    assert lookup_row_by_rid("n_999", 5) is None;
    assert lookup_row_by_rid("", 5) is None;
}

test "lookup_known_rid" {
    row = lookup_row_by_rid("n_3", 5);
    assert row is not None;
    assert row == [3, 3];
}
