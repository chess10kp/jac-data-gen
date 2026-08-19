node Isle { has name: str; has counted: bool = False; }

walker Survey {
    has size: int = 0;
    can tally with Isle entry {
        if not here.counted {
            here.counted = True;
            self.size += 1;
            visit [-->];
        }
    }
}

def component_size(spec: dict) -> int {
    reg: dict = {};
    for nm in list(spec["nodes"]) { reg[nm] = Isle(name=str(nm)); }
    for pr in list(spec["links"]) { reg[pr[0]] <++> reg[pr[1]]; }
    w = reg[spec["member"]] spawn Survey();
    return w.size;
}

with entry {
    print(component_size({'nodes': ['a', 'b', 'c', 'd', 'e'], 'links': [['a', 'b'], ['b', 'c'], ['d', 'e']], 'member': 'b'}));
}
