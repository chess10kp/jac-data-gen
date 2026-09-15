"""maik-hasler/vocational-training-resources#3 — recursive level progression path (manual recursive CTE lift)."""

node Level {
    has cid: str;
    has num: int;
    has xp_step: int;
}

edge Next {}

walker PathWalker {
    has claimed: dict[str, bool] = {};
    has end_lvl: int = 5;
    has cumulative: int = 0;
    has rows: list = [];

    can walk with Level entry {
        if here.cid in self.claimed {
            skip;
        }
        if here.num > self.end_lvl {
            skip;
        }
        self.claimed[here.cid] = True;
        row: dict = {};
        row["level"] = here.num;
        row["xp_step"] = here.xp_step;
        row["cumulative_xp"] = self.cumulative;
        self.rows.append(row);
        print("visit level", here.num, "cumulative", self.cumulative);
        if here.num < self.end_lvl {
            kids: list[Level] = [here ->:Next:->][?:Level];
            if kids {
                self.cumulative += here.xp_step;
                visit :0: kids;
            } else {
                disengage;
            }
        }
    }
}

def sorted_level_keys(xp_steps: dict[int, int]) -> list[int] {
    keys: list[int] = [];
    for lvl in xp_steps {
        keys.append(lvl);
    }
    return sorted(keys);
}

def find_level(graph_root: Level, target: int) -> Level | None {
    cur: Level | None = graph_root;
    while cur is not None {
        if cur.num == target {
            return cur;
        }
        if cur.num > target {
            return None;
        }
        nxt_list: list[Level] = [cur ->:Next:->][?:Level];
        if not nxt_list {
            return None;
        }
        cur = nxt_list[0];
    }
    return None;
}

def build_progression_graph(xp_steps: dict[int, int]) -> Level {
    levels: list[int] = sorted_level_keys(xp_steps);
    first: Level | None = None;
    prev: Level | None = None;
    for num in levels {
        step_val: int = xp_steps[num];
        nd = Level(cid="L" + str(num), num=num, xp_step=step_val);
        root ++> nd;
        if first is None {
            first = nd;
        }
        if prev is not None {
            prev +>:Next:+> nd;
        }
        prev = nd;
    }
    if first is None {
        empty = Level(cid="L0", num=0, xp_step=0);
        root ++> empty;
        return empty;
    }
    return first;
}

def recursive_level_path(
    graph_root: Level,
    start_level: int,
    end_level: int
) -> list {
    if start_level > end_level {
        return [];
    }
    start_node: Level | None = find_level(graph_root, start_level);
    if start_node is None {
        return [];
    }
    w = start_node spawn PathWalker(
        claimed={},
        end_lvl=end_level,
        cumulative=0,
        rows=[]
    );
    print("path_len", len(w.rows));
    return w.rows;
}

test "linear_chain_xp" {
    xp: dict[int, int] = {1: 10, 2: 20, 3: 30};
    g = build_progression_graph(xp);
    rows = recursive_level_path(g, 1, 3);
    levels: list[int] = [];
    cumulatives: list[int] = [];
    for r in rows {
        levels.append(r["level"]);
        cumulatives.append(r["cumulative_xp"]);
    }
    assert levels == [1, 2, 3];;
    assert cumulatives == [0, 10, 30];;
}

test "diamond_revisit_claim_skip" {
    a = Level(cid="L1", num=1, xp_step=10);
    b = Level(cid="L2a", num=2, xp_step=20);
    c = Level(cid="L2b", num=2, xp_step=20);
    d = Level(cid="L3", num=3, xp_step=30);
    root ++> a;
    a +>:Next:+> b;
    a +>:Next:+> c;
    b +>:Next:+> d;
    c +>:Next:+> d;
    w = a spawn PathWalker(claimed={}, end_lvl=3, cumulative=0, rows=[]);
    levels_seen: list[int] = [];
    for r in w.rows {
        levels_seen.append(r["level"]);
    }
    assert sorted(levels_seen) == [1, 2, 2, 3];;
}

test "diamond_shared_tail_skip" {
    a = Level(cid="L1", num=1, xp_step=10);
    b = Level(cid="L2a", num=2, xp_step=20);
    c = Level(cid="L2b", num=2, xp_step=20);
    d = Level(cid="L3", num=3, xp_step=30);
    root ++> a;
    a +>:Next:+> b;
    a +>:Next:+> c;
    b +>:Next:+> d;
    c +>:Next:+> d;
    w = a spawn PathWalker(claimed={}, end_lvl=3, cumulative=0, rows=[]);
    cids: list[str] = [];
    for r in w.rows {
        cids.append(r["level"]);
    }
    assert len(w.rows) == 4;;
    assert sorted(cids) == [1, 2, 2, 3];;
}

test "empty_xp_table" {
    g = build_progression_graph({});
    rows = recursive_level_path(g, 0, 5);
    assert len(rows) == 1;;
    assert rows[0]["level"] == 0;;
    assert rows[0]["xp_step"] == 0;;
    assert rows[0]["cumulative_xp"] == 0;;
}

test "start_gt_end_empty" {
    xp: dict[int, int] = {1: 10};
    g = build_progression_graph(xp);
    rows = recursive_level_path(g, 3, 1);
    assert len(rows) == 0;;
}

test "missing_start_level" {
    xp: dict[int, int] = {1: 10, 2: 20};
    g = build_progression_graph(xp);
    rows = recursive_level_path(g, 9, 10);
    assert len(rows) == 0;;
}
