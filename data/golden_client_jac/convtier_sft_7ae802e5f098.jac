node GN_sum_reachable { has name: str; has val: int; has seen: bool = False; }

walker W_sum_reachable {
    has total: int = 0;
    can step with GN_sum_reachable entry {
        if not here.seen { here.seen = True; self.total += here.val; visit [-->]; }
    }
}

def sum_reachable(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = GN_sum_reachable(name=str(nm), seen=False, val=int(vals[nm])); }
    for (s, ts) in adj.items() { for t in list(ts) { if t not in nodes { nodes[t] = GN_sum_reachable(name=str(t), seen=False, val=int(vals[t])); } } }
    for (s, ts) in adj.items() { for t in list(ts) { nodes[s] ++> nodes[t]; } }
    w = nodes[start] spawn W_sum_reachable();
    return w.total;
}

with entry {
    print(sum_reachable({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'start': 'a', 'vals': {'a': 5, 'b': 8, 'c': 2, 'd': 10}}));
}
