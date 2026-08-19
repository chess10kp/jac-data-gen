node Reef { has name: str; has dived: bool = False; }

walker Dive {
    has area: int = 0;
    can swim with Reef entry {
        if not here.dived {
            here.dived = True;
            self.area += 1;
            visit [-->];
        }
    }
}

def biggest_island(spec: dict) -> int {
    reg: dict = {};
    for nm in list(spec["nodes"]) { reg[nm] = Reef(name=str(nm)); }
    for pr in list(spec["links"]) { reg[pr[0]] <++> reg[pr[1]]; }
    best: int = 0;
    for nm in list(spec["nodes"]) {
        if not reg[nm].dived {
            w = reg[nm] spawn Dive();
            if w.area > best { best = w.area; }
        }
    }
    return best;
}

with entry {
    print(biggest_island({'nodes': ['a', 'b', 'c', 'd', 'e', 'f'], 'links': [['a', 'b'], ['b', 'c'], ['e', 'f']]}));
}
