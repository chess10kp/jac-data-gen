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
