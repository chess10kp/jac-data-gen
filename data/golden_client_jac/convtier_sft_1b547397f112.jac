node Pipe { has name: str; has flow: int; has shut: bool; has traced: bool = False; }

walker Flow {
    has total: int = 0;
    can trace with Pipe entry {
        if not here.traced {
            here.traced = True;
            if not here.shut {
                self.total += here.flow;
                visit [-->];
            }
        }
    }
}

def sum_unblocked(spec: dict) -> int {
    adj: dict = spec["adj"]; vals: dict = spec["vals"]; blocked: dict = spec["blocked"];
    built: dict = {};
    for (u, vs) in adj.items() {
        if u not in built { built[u] = Pipe(name=u, flow=vals[u], shut=blocked[u]); }
        for v in vs { if v not in built { built[v] = Pipe(name=v, flow=vals[v], shut=blocked[v]); } }
    }
    for (u, vs) in adj.items() { for v in vs { built[u] ++> built[v]; } }
    wk = built[spec["start"]] spawn Flow();
    return wk.total;
}

with entry {
    print(sum_unblocked({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'vals': {'a': 1, 'b': 10, 'c': 2, 'd': 4}, 'blocked': {'a': False, 'b': True, 'c': False, 'd': False}, 'start': 'a'}));
}
