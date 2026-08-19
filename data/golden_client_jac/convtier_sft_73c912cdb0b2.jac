node GN_count_branches { has name: str; has nkids: int; has seen: bool = False; }

walker W_count_branches {
    has count: int = 0;
    can step with GN_count_branches entry {
        if not here.seen { here.seen = True; if here.nkids >= 2 { self.count += 1; } visit [-->]; }
    }
}

def count_branches(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = GN_count_branches(name=str(nm), seen=False, nkids=len(list(adj[nm]))); }
    for (s, ts) in adj.items() { for t in list(ts) { if t not in nodes { nodes[t] = GN_count_branches(name=str(t), seen=False, nkids=0); } } }
    for (s, ts) in adj.items() { for t in list(ts) { nodes[s] ++> nodes[t]; } }
    w = nodes[start] spawn W_count_branches();
    return w.count;
}

with entry {
    print(count_branches({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'start': 'a'}));
}
