node GN_min_reachable { has name: str; has val: int; has seen: bool = False; }

walker W_min_reachable {
    has best: int = 2147483647;
    can step with GN_min_reachable entry {
        if not here.seen { here.seen = True; if here.val < self.best { self.best = here.val; } visit [-->]; }
    }
}

def min_reachable(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = GN_min_reachable(name=str(nm), seen=False, val=int(vals[nm])); }
    for (s, ts) in adj.items() { for t in list(ts) { if t not in nodes { nodes[t] = GN_min_reachable(name=str(t), seen=False, val=int(vals[t])); } } }
    for (s, ts) in adj.items() { for t in list(ts) { nodes[s] ++> nodes[t]; } }
    w = nodes[start] spawn W_min_reachable();
    return w.best;
}

with entry {
    print(min_reachable({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'start': 'a', 'vals': {'a': 5, 'b': 8, 'c': 2, 'd': 10}}));
}
