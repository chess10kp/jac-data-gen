node Crate { has name: str; has weight: int; has lifted: bool = False; }

walker CapMax {
    has cap: int;
    has best: int = -1;
    can lift with Crate entry {
        if not here.lifted {
            here.lifted = True;
            if here.weight < self.cap and here.weight > self.best { self.best = here.weight; }
            visit [-->];
        }
    }
}

def max_under_cap(spec: dict) -> int {
    adj: dict = spec["adj"]; vals: dict = spec["vals"];
    all_names: list = list(adj.keys());
    for ends in adj.values() { for e in ends { if e not in all_names { all_names.append(e); } } }
    crates: dict = {};
    for nm in all_names { crates[nm] = Crate(name=nm, weight=vals[nm]); }
    for (src, ends) in adj.items() { for e in ends { crates[src] ++> crates[e]; } }
    agent = crates[spec["start"]] spawn CapMax(cap=spec["cap"]);
    return agent.best;
}

with entry {
    print(max_under_cap({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'vals': {'a': 12, 'b': 7, 'c': 20, 'd': 9}, 'start': 'a', 'cap': 10}));
}
