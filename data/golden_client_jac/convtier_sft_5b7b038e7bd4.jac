node Site { has name: str; has seen: bool = False; }

walker ReachProbe {
    has target: str;
    has found: bool = False;
    can launch with Root entry { visit [-->][?:Site]; }
    can sweep with Site entry {
        if not here.seen {
            here.seen = True;
            if here.name == self.target { self.found = True; }
            visit [-->][?:Site];
        }
    }
}

def reachable_from_root(spec: dict) -> bool {
    for old in [root -->] { root del --> old; }
    sites: dict = {};
    names: list = list(spec["gateways"]) + list(spec["links"].keys());
    for ts in spec["links"].values() { names += list(ts); }
    for nm in names {
        if nm not in sites { sites[nm] = Site(name=str(nm)); }
    }
    for g in list(spec["gateways"]) { root ++> sites[g]; }
    for (s, ts) in spec["links"].items() {
        for t in list(ts) { sites[s] ++> sites[t]; }
    }
    return (root spawn ReachProbe(target=str(spec["target"]))).found;
}

with entry {
    print(reachable_from_root({'gateways': ['a'], 'links': {'a': ['b'], 'b': ['c'], 'c': ['a']}, 'target': 'c'}));
}
