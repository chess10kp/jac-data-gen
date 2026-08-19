node Atoll { has name: str; has charted: bool = False; }

walker Chart {
    can spread with Atoll entry {
        if not here.charted {
            here.charted = True;
            visit [-->];
        }
    }
}

def count_islands(spec: dict) -> int {
    reg: dict = {};
    for nm in list(spec["nodes"]) { reg[nm] = Atoll(name=str(nm)); }
    for pr in list(spec["links"]) { reg[pr[0]] <++> reg[pr[1]]; }
    islands: int = 0;
    for nm in list(spec["nodes"]) {
        if not reg[nm].charted {
            islands += 1;
            reg[nm] spawn Chart();
        }
    }
    return islands;
}

with entry {
    print(count_islands({'nodes': ['a', 'b', 'c', 'd', 'e'], 'links': [['a', 'b'], ['c', 'd']]}));
}
