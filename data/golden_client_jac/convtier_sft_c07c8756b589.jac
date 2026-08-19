node Site { has label: str; has done: bool = False; }

walker Collector {
    has bag: list = [];
    can scoop with Site entry {
        if not here.done {
            here.done = True;
            self.bag.append(here.label);
            visit [-->];
        }
    }
}

def gather_reachable(spec: dict) -> list {
    adj: dict = dict(spec["adj"]);
    sites: dict = {};
    for (u, vs) in adj.items() {
        if u not in sites { sites[u] = Site(label=str(u)); }
        for v in vs {
            if v not in sites { sites[v] = Site(label=str(v)); }
            sites[u] ++> sites[v];
        }
    }
    w = sites[spec["start"]] spawn Collector();
    return sorted(w.bag);
}

with entry {
    print(gather_reachable({'adj': {'m': ['n', 'k'], 'n': ['m'], 'k': [], 'z': ['m']}, 'start': 'm'}));
}
