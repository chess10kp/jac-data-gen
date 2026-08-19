node GN_range_reachable { has name: str; has val: int; has seen: bool = False; }

walker W_range_reachable {
    has lo: int = 2147483647;
    has hi: int = -2147483648;
    can step with GN_range_reachable entry {
        if not here.seen { here.seen = True; if here.val < self.lo { self.lo = here.val; } if here.val > self.hi { self.hi = here.val; } visit [-->]; }
    }
}

def range_reachable(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = GN_range_reachable(name=str(nm), seen=False, val=int(vals[nm])); }
    for (s, ts) in adj.items() { for t in list(ts) { if t not in nodes { nodes[t] = GN_range_reachable(name=str(t), seen=False, val=int(vals[t])); } } }
    for (s, ts) in adj.items() { for t in list(ts) { nodes[s] ++> nodes[t]; } }
    w = nodes[start] spawn W_range_reachable();
    return w.hi - w.lo;
}

with entry {
    print(range_reachable({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'start': 'a', 'vals': {'a': 5, 'b': 8, 'c': 2, 'd': 10}}));
}
