node Junction { has name: str; has da: int = -1; has db: int = -1; has seen_a: bool = False; has seen_b: bool = False; }

walker StampA {
    can roam with Junction entry {
        if not here.seen_a {
            here.seen_a = True;
            for nxt in [-->] {
                if nxt.da == -1 { nxt.da = here.da + 1; }
            }
            visit [-->];
        }
    }
}

walker StampB {
    can roam with Junction entry {
        if not here.seen_b {
            here.seen_b = True;
            for nxt in [-->] {
                if nxt.db == -1 { nxt.db = here.db + 1; }
            }
            visit [-->];
        }
    }
}

def best_meeting_point(spec: dict) -> str {
    adj: dict = dict(spec["adj"]);
    grid: dict = {};
    for nm in adj.keys() { grid[nm] = Junction(name=str(nm)); }
    for (a, bs) in adj.items() { for b in bs { grid[a] ++> grid[b]; } }
    left = grid[str(spec["a"])];
    right = grid[str(spec["b"])];
    left.da = 0;
    right.db = 0;
    wa = left spawn StampA();
    wb = right spawn StampB();
    best: str = "";
    cost: int = -1;
    for nm in sorted(grid.keys()) {
        j = grid[nm];
        if j.da != -1 and j.db != -1 {
            c: int = j.da + j.db;
            if cost == -1 or c < cost { best = nm; cost = c; }
        }
    }
    if cost == -1 { return "none"; }
    return best + ":" + str(cost);
}

with entry {
    print(best_meeting_point({'adj': {'a': ['c'], 'b': ['c'], 'c': ['d'], 'd': []}, 'a': 'a', 'b': 'b'}));
}
