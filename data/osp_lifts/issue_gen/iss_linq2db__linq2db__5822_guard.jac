# linq2db/linq2db#5822
# Preserve UNION distinctness before computing the outer projection.

node CteStart {
    has label: str = "recursive-union";
}

node CteRow {
    has rid: str;
    has counter: int;
    has day: int;
}

edge Seed {}
edge Next {}

obj CteState {
    has start: CteStart;
}

walker CollectRows {
    has claimed: dict[str, bool] = {};
    has found: list[CteRow] = [];

    can step_start with CteStart entry {
        print here.label;
        kids: list[CteRow] = [];
        for kid in [here ->:Seed:->][?:CteRow] {
            kids.append(kid);
        }
        visit :0: [kids];
    }

    can step_row with CteRow entry {
        print here.rid;
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here);

        kids: list[CteRow] = [];
        for kid in [here ->:Next:->][?:CteRow] {
            kids.append(kid);
        }
        visit :0: [kids];
    }
}

def recursive_union_projection(
    ids: list[str],
    counters: list[int],
    days: list[int],
    links: dict[str, list[str]] | None = None
) -> list[int] {
    if len(ids) != len(counters) {
        return [];
    }
    if len(ids) != len(days) {
        return [];
    }

    graph_root: CteStart = CteStart();
    state = CteState(start=graph_root);
    by_id: dict[str, CteRow] = {};
    adjacency: dict[str, list[str]] = {};
    if links is not None {
        adjacency = links;
    }

    index: int = 0;
    for rid in ids {
        row: CteRow = CteRow(
            rid=rid,
            counter=counters[index],
            day=days[index]
        );
        by_id[rid] = row;
        graph_root +>:Seed:+> row;
        index += 1;
    }

    for parent_id in ids {
        if parent_id in adjacency {
            parent: CteRow = by_id[parent_id];
            for child_id in adjacency[parent_id] {
                if child_id in by_id {
                    child: CteRow = by_id[child_id];
                    parent +>:Next:+> child;
                }
            }
        }
    }

    if len(ids) == 0 {
        return [];
    }

    w = state.start spawn CollectRows(claimed={});
    unique_rows: list[CteRow] = [];
    projected: list[int] = [];

    for row in w.found {
        duplicate: bool = False;
        for prior in unique_rows {
            if prior.counter == row.counter && prior.day == row.day {
                duplicate = True;
            }
        }
        if duplicate == False {
            unique_rows.append(row);
            projected.append(row.day % 10);
        }
    }

    return sorted(projected);
}

test "diamond revisit" {
    values = recursive_union_projection(
        ["a", "b", "c", "d"],
        [1, 2, 2, 3],
        [20240101, 20240102, 20240103, 20240104],
        {"a": ["b", "c"], "b": ["d"], "c": ["d"]}
    );
    assert (values == [1, 2, 3, 4]);
}

test "unknown ids and cycle are tolerated" {
    values = recursive_union_projection(
        ["a"],
        [1],
        [20240101],
        {"a": ["missing", "a"], "missing": ["a"]}
    );
    assert (values == [1]);
}

test "union distinct precedes projection" {
    values = recursive_union_projection(
        ["a", "b"],
        [1, 1],
        [20240101, 20240111],
        {}
    );
    assert (values == [1, 1]);
}

test "empty and malformed inputs" {
    empty_values = recursive_union_projection([], [], [], None);
    malformed_values = recursive_union_projection(["a"], [], [20240101], None);
    assert (empty_values == []);
    assert (malformed_values == []);
}
