edge Road {}
edge Rail {}
node Junction { has name: str; has dr: int = -1; has dl: int = -1; has sr: bool = False; has sl: bool = False; }

walker RoadHops {
    can step with Junction entry {
        if not here.sr {
            here.sr = True;
            for nxt in [->:Road:->] { if nxt.dr == -1 { nxt.dr = here.dr + 1; } }
            visit [->:Road:->];
        }
    }
}

walker RailHops {
    can step with Junction entry {
        if not here.sl {
            here.sl = True;
            for nxt in [->:Rail:->] { if nxt.dl == -1 { nxt.dl = here.dl + 1; } }
            visit [->:Rail:->];
        }
    }
}

def faster_mode_hops(spec: dict) -> int {
    reg: dict = {};
    for nm in [spec["start"], spec["target"]] { if nm not in reg { reg[nm] = Junction(name=nm); } }
    for pr in spec["roads"] { for nm in pr { if nm not in reg { reg[nm] = Junction(name=nm); } } }
    for pr in spec["rails"] { for nm in pr { if nm not in reg { reg[nm] = Junction(name=nm); } } }
    for pr in spec["roads"] { reg[pr[0]] +>:Road:+> reg[pr[1]]; }
    for pr in spec["rails"] { reg[pr[0]] +>:Rail:+> reg[pr[1]]; }
    base = reg[spec["start"]];
    base.dr = 0;
    base.dl = 0;
    wa = base spawn RoadHops();
    wb = base spawn RailHops();
    goal = reg[spec["target"]];
    if goal.dr == -1 { return goal.dl; }
    if goal.dl == -1 { return goal.dr; }
    if goal.dr < goal.dl { return goal.dr; }
    return goal.dl;
}

with entry {
    print(faster_mode_hops({'roads': [['a', 'b'], ['b', 't']], 'rails': [['a', 't']], 'start': 'a', 'target': 't'}));
}
