"""pavanvd/postgres-xl#22 — recursive CTE-style count-up (WITH RECURSIVE evaluation)."""

node Row {
    has n: int;
    has cid: str;
}

edge Next {}

walker ExpandCollect {
    has upper: int;
    has claimed: dict[str, bool] = {};
    has out: list[int] = [];

    can grow with Row entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.out.append(here.n);
        print("expand", here.n);
        kids: list[Row] = [];
        if here.n < self.upper {
            nxt_n: int = here.n + 1;
            nxt_cid: str = "r_" + str(nxt_n);
            child: Row | None = None;
            linked: list[Row] = [here ->:Next:->][?:Row];
            for ch in linked {
                if ch.cid == nxt_cid {
                    child = ch;
                }
            }
            if child is None {
                child = Row(n=nxt_n, cid=nxt_cid);
                here +>:Next:+> child;
            }
            kids.append(child);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker WalkCollect {
    has claimed: dict[str, bool] = {};
    has out: list[int] = [];

    can step with Row entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.out.append(here.n);
        print("collect", here.n);
        kids: list[Row] = [];
        for ch in [here ->:Next:->][?:Row] {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

walker CidLookup {
    has want: str;
    has claimed: dict[str, bool] = {};
    has found: Row | None = None;

    can seek with Row entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.want {
            self.found = here;
            disengage;
        }
        kids: list[Row] = [];
        for ch in [here ->:Next:->][?:Row] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def seed_row(n: int) -> Row {
    cid: str = "r_" + str(n);
    nd: Row = Row(n=n, cid=cid);
    root ++> nd;
    return nd;
}

def build_diamond_rows -> Row {
    r1: Row = Row(n=1, cid="r_1");
    r2: Row = Row(n=2, cid="r_2");
    r3: Row = Row(n=3, cid="r_3");
    r4: Row = Row(n=4, cid="r_4");
    root ++> r1;
    r1 +>:Next:+> r2;
    r1 +>:Next:+> r3;
    r2 +>:Next:+> r4;
    r3 +>:Next:+> r4;
    return r1;
}

def recursive_count_up(start: int, upper_bound: int) -> list[int] {
    head: Row = seed_row(start);
    w = head spawn ExpandCollect(upper=upper_bound, claimed={});
    vals: list[int] = [];
    for v in w.out {
        vals.append(v);
    }
    return vals;
}

def walk_collect(graph_root: Row) -> list[int] {
    w = graph_root spawn WalkCollect(claimed={});
    vals: list[int] = [];
    for v in w.out {
        vals.append(v);
    }
    return vals;
}

def row_by_cid(graph_root: Row, cid: str) -> Row | None {
    w = graph_root spawn CidLookup(want=cid, claimed={});
    return w.found;
}

test "recursive_count_up_chain" {
    got = recursive_count_up(1, 5);
    assert got == [1, 2, 3, 4, 5];
}

test "recursive_count_up_singleton" {
    got = recursive_count_up(3, 3);
    assert got == [3];
}

test "walk_collect_diamond_once_only" {
    root_node = build_diamond_rows();
    got = walk_collect(root_node);
    assert got == [1, 2, 4, 3];
}

test "row_by_cid_found" {
    root_node = build_diamond_rows();
    hit = row_by_cid(root_node, "r_4");
    assert hit is not None;
    assert hit.n == 4;
}

test "row_by_cid_missing" {
    root_node = build_diamond_rows();
    hit = row_by_cid(root_node, "r_99");
    assert hit is None;
}

test "seed_row_fields" {
    nd = seed_row(7);
    assert nd.n == 7;
    assert nd.cid == "r_7";
}
