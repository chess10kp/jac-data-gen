node GN_count_reachable { has name: str; has seen: bool = False; }

walker W_count_reachable {
    has count: int = 0;
    can step with GN_count_reachable entry {
        if not here.seen { here.seen = True; self.count += 1; visit [-->]; }
    }
}

def count_reachable(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = GN_count_reachable(name=str(nm), seen=False); }
    for (s, ts) in adj.items() { for t in list(ts) { if t not in nodes { nodes[t] = GN_count_reachable(name=str(t), seen=False); } } }
    for (s, ts) in adj.items() { for t in list(ts) { nodes[s] ++> nodes[t]; } }
    w = nodes[start] spawn W_count_reachable();
    return w.count;
}

with entry {
    print(count_reachable({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'start': 'a'}));
}
