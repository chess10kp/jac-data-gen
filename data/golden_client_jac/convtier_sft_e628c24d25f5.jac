edge Road { has w: int; }
node WC { has name: str; has seen: bool = False; }

walker SumW {
    has total: int = 0;
    can step with WC entry {
        if not here.seen {
            here.seen = True;
            for e in [edge here -->] { self.total += e.w; }
            visit [-->];
        }
    }
}

def sum_edge_weights(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); start: str = str(spec["start"]);
    nodes: dict = {};
    for nm in adj.keys() { nodes[nm] = WC(name=str(nm)); }
    for (s, ts) in adj.items() { for pr in list(ts) { tg = str(pr[0]); if tg not in nodes { nodes[tg] = WC(name=tg); } } }
    for (s, ts) in adj.items() { for pr in list(ts) { nodes[s] +>:Road(w=int(pr[1])):+> nodes[str(pr[0])]; } }
    w = nodes[start] spawn SumW();
    return w.total;
}

with entry {
    print(sum_edge_weights({'adj': {'a': [['b', 5], ['c', 3]], 'b': [['c', 2]], 'c': []}, 'start': 'a'}));
}
