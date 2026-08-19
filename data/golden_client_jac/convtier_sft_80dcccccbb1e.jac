node Town { has title: str; has band: int = -1; }

walker Mapper {
    has cap: int;
    has found: list = [];
    can chart with Town entry {
        self.found.append(here.title);
        if here.band < self.cap {
            for nb in [-->] {
                if nb.band == -1 { nb.band = here.band + 1; visit nb; }
            }
        }
    }
}

def names_within_depth(spec: dict) -> list {
    towns: dict = {};
    for pr in list(spec["edges"]) {
        u: str = str(pr[0]); v: str = str(pr[1]);
        if u not in towns { towns[u] = Town(title=u); }
        if v not in towns { towns[v] = Town(title=v); }
        towns[u] ++> towns[v];
    }
    start: str = str(spec["start"]);
    if start not in towns { towns[start] = Town(title=start); }
    towns[start].band = 0;
    w = towns[start] spawn Mapper(cap=int(spec["depth"]));
    return sorted(w.found);
}

with entry {
    print(names_within_depth({'edges': [['c', 'a'], ['c', 'b'], ['a', 'd']], 'start': 'c', 'depth': 1}));
}
