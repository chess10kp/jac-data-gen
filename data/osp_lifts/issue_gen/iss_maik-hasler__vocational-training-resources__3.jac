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
