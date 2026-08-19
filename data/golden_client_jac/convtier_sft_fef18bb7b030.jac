node Unit { has name: str; has depth: int = 0; }

walker DepthGauge {
    has deepest: int = 0;
    can launch with Root entry {
        for t in [-->][?:Unit] { if t.depth == 0 { t.depth = 1; } }
        visit [-->][?:Unit];
    }
    can plumb with Unit entry {
        if here.depth > self.deepest { self.deepest = here.depth; }
        for c in [-->][?:Unit] {
            if c.depth == 0 { c.depth = here.depth + 1; visit c; }
        }
    }
}

def registry_depth(spec: dict) -> int {
    for old in [root -->] { root del --> old; }
    units: dict = {};
    names: list = list(spec["tops"]) + list(spec["tree"].keys());
    for cs in spec["tree"].values() { names += list(cs); }
    for nm in names {
        if nm not in units { units[nm] = Unit(name=str(nm)); }
    }
    for t in list(spec["tops"]) { root ++> units[t]; }
    for (p, cs) in spec["tree"].items() {
        for c in list(cs) { units[p] ++> units[c]; }
    }
    return (root spawn DepthGauge()).deepest;
}

with entry {
    print(registry_depth({'tops': ['a', 'b'], 'tree': {'a': ['c'], 'c': ['d']}}));
}
