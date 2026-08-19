node GN_count_negative { has name: str; has val: int; has seen: bool = False; }

walker W_count_negative {
    has count: int = 0;
    can step with GN_count_negative entry {
        if not here.seen { here.seen = True; if here.val < 0 { self.count += 1; } visit [-->]; }
    }
}

def count_negative(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = GN_count_negative(name=str(nm), seen=False, val=int(vals[nm])); }
    for (s, ts) in adj.items() { for t in list(ts) { if t not in nodes { nodes[t] = GN_count_negative(name=str(t), seen=False, val=int(vals[t])); } } }
    for (s, ts) in adj.items() { for t in list(ts) { nodes[s] ++> nodes[t]; } }
    w = nodes[start] spawn W_count_negative();
    return w.count;
}

with entry {
    print(count_negative({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'start': 'a', 'vals': {'a': 5, 'b': 8, 'c': 2, 'd': 10}}));
}
