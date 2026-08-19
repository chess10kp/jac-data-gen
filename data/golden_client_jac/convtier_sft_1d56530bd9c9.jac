node GN_sum_leaf_values { has name: str; has val: int; has nkids: int; has seen: bool = False; }

walker W_sum_leaf_values {
    has total: int = 0;
    can step with GN_sum_leaf_values entry {
        if not here.seen { here.seen = True; if here.nkids == 0 { self.total += here.val; } visit [-->]; }
    }
}

def sum_leaf_values(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    vals: dict = dict(spec["vals"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = GN_sum_leaf_values(name=str(nm), seen=False, val=int(vals[nm]), nkids=len(list(adj[nm]))); }
    for (s, ts) in adj.items() { for t in list(ts) { if t not in nodes { nodes[t] = GN_sum_leaf_values(name=str(t), seen=False, val=int(vals[t]), nkids=0); } } }
    for (s, ts) in adj.items() { for t in list(ts) { nodes[s] ++> nodes[t]; } }
    w = nodes[start] spawn W_sum_leaf_values();
    return w.total;
}

with entry {
    print(sum_leaf_values({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'start': 'a', 'vals': {'a': 5, 'b': 8, 'c': 2, 'd': 10}}));
}
