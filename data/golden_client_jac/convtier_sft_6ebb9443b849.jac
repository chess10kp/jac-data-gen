edge Road { has w: int; }
node WC { has name: str; has seen: bool = False; }

walker MaxE {
    has best: int = 0;
    can step with WC entry {
        if not here.seen {
            here.seen = True;
            for e in [edge here -->] { if e.w > self.best { self.best = e.w; } }
            visit [-->];
        }
    }
}

def max_edge_weight(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = WC(name=str(nm)); }
    for (s, ts) in adj.items() { for pr in list(ts) { tg = str(pr[0]); if tg not in nodes { nodes[tg] = WC(name=tg); } } }
    for (s, ts) in adj.items() { for pr in list(ts) { nodes[s] +>:Road(w=int(pr[1])):+> nodes[str(pr[0])]; } }
    w = nodes[start] spawn MaxE();
    return w.best;
}

with entry {
    print(max_edge_weight({'adj': {'a': [['b', 5], ['c', 3]], 'b': [['c', 2]], 'c': []}, 'start': 'a'}));
}
