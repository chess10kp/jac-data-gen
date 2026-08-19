node Vault { has vid: str; has worth: int; has stage: int = -1; }

walker Quest {
    has bar: int;
    has cap: int;
    has result: int = -1;
    can dig with Vault entry {
        if here.worth >= self.bar { self.result = here.stage; disengage; }
        if here.stage < self.cap {
            for nb in [-->] {
                if nb.stage == -1 { nb.stage = here.stage + 1; visit nb; }
            }
        }
    }
}

def min_hops_to_threshold(spec: dict) -> int {
    riches: dict = dict(spec["vals"]);
    vaults: dict = {};
    for (nm, v) in riches.items() { vaults[nm] = Vault(vid=str(nm), worth=int(v)); }
    for (s, ts) in dict(spec["adj"]).items() { for t in list(ts) { vaults[s] ++> vaults[t]; } }
    vaults[spec["start"]].stage = 0;
    w = vaults[spec["start"]] spawn Quest(bar=int(spec["threshold"]), cap=int(spec["limit"]));
    return w.result;
}

with entry {
    print(min_hops_to_threshold({'adj': {'a': ['b'], 'b': ['c'], 'c': ['d'], 'd': []}, 'vals': {'a': 1, 'b': 2, 'c': 50, 'd': 99}, 'start': 'a', 'limit': 3, 'threshold': 40}));
}
