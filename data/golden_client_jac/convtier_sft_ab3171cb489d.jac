node Town { has name: str; has d: int = 0; }
edge Road { has dist: int; }

walker PathMeter {
    has target: str;
    has result: int = -1;
    can walk with Town entry {
        if here.name == self.target {
            self.result = here.d;
            disengage;
        }
        for (nb, e) in zip([-->], [edge -->]) { nb.d = here.d + e.dist; }
        visit [-->];
    }
}

def trail_dist_to(spec: dict) -> int {
    nodes: dict = {};
    for tr in spec["edges"] {
        for nm in [tr[0], tr[1]] {
            if nm not in nodes { nodes[nm] = Town(name=str(nm)); }
        }
    }
    for tr in spec["edges"] { nodes[tr[0]] +>:Road(dist=int(tr[2])):+> nodes[tr[1]]; }
    w = nodes[spec["start"]] spawn PathMeter(target=str(spec["target"]));
    return w.result;
}

with entry {
    print(trail_dist_to({'edges': [['a', 'b', 3], ['a', 'c', 7], ['b', 'd', 2]], 'start': 'a', 'target': 'd'}));
}
