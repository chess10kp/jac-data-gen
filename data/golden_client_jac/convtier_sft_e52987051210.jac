node GN_count_leaf_or_branch { has name: str; has nkids: int; has seen: bool = False; }

walker W_count_leaf_or_branch {
    has count: int = 0;
    can step with GN_count_leaf_or_branch entry {
        if not here.seen { here.seen = True; if here.nkids != 1 { self.count += 1; } visit [-->]; }
    }
}

def count_leaf_or_branch(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = GN_count_leaf_or_branch(name=str(nm), seen=False, nkids=len(list(adj[nm]))); }
    for (s, ts) in adj.items() { for t in list(ts) { if t not in nodes { nodes[t] = GN_count_leaf_or_branch(name=str(t), seen=False, nkids=0); } } }
    for (s, ts) in adj.items() { for t in list(ts) { nodes[s] ++> nodes[t]; } }
    w = nodes[start] spawn W_count_leaf_or_branch();
    return w.count;
}

with entry {
    print(count_leaf_or_branch({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'start': 'a'}));
}
