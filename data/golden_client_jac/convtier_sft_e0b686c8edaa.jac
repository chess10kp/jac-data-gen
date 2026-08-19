edge Road {}
edge Rail {}
node Site { has name: str; has sa: bool = False; has sr: bool = False; has sl: bool = False; }

walker AnyReach {
    can step with Site entry {
        if not here.sa {
            here.sa = True;
            visit [-->];
        }
    }
}

walker PureRoad {
    can step with Site entry {
        if not here.sr {
            here.sr = True;
            visit [->:Road:->];
        }
    }
}

walker PureRail {
    can step with Site entry {
        if not here.sl {
            here.sl = True;
            visit [->:Rail:->];
        }
    }
}

def mixed_only_count(spec: dict) -> int {
    reg: dict = {};
    reg[spec["start"]] = Site(name=spec["start"]);
    for pr in spec["roads"] { for nm in pr { if nm not in reg { reg[nm] = Site(name=nm); } } }
    for pr in spec["rails"] { for nm in pr { if nm not in reg { reg[nm] = Site(name=nm); } } }
    for pr in spec["roads"] { reg[pr[0]] +>:Road:+> reg[pr[1]]; }
    for pr in spec["rails"] { reg[pr[0]] +>:Rail:+> reg[pr[1]]; }
    base = reg[spec["start"]];
    w1 = base spawn AnyReach();
    w2 = base spawn PureRoad();
    w3 = base spawn PureRail();
    count: int = 0;
    for nd in reg.values() { if nd.sa and not nd.sr and not nd.sl { count += 1; } }
    return count;
}

with entry {
    print(mixed_only_count({'roads': [['a', 'b']], 'rails': [['b', 'c']], 'start': 'a'}));
}
