node GN_count_abs_above { has name: str; has val: int; has seen: bool = False; }

walker W_count_abs_above {
    has k: int;
    has count: int = 0;
    can step with GN_count_abs_above entry {
        if not here.seen { here.seen = True; if (here.val if here.val >= 0 else -here.val) > self.k { self.count += 1; } visit [-->]; }
    }
}

def count_abs_above(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    vals: dict = dict(spec["vals"]);
    thr: int = int(spec["threshold"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = GN_count_abs_above(name=str(nm), seen=False, val=int(vals[nm])); }
    for (s, ts) in adj.items() { for t in list(ts) { if t not in nodes { nodes[t] = GN_count_abs_above(name=str(t), seen=False, val=int(vals[t])); } } }
    for (s, ts) in adj.items() { for t in list(ts) { nodes[s] ++> nodes[t]; } }
    w = nodes[start] spawn W_count_abs_above(k=thr);
    return w.count;
}

with entry {
    print(count_abs_above({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'start': 'a', 'vals': {'a': 5, 'b': 8, 'c': 2, 'd': 10}, 'threshold': 5}));
}
