edge Road { has toll: int; }
edge Ferry { has fare: int; }
node Port { has name: str; has seen: bool = False; }

walker CostAudit {
    has tolls: int = 0;
    has fares: int = 0;
    can tally with Port entry {
        if not here.seen {
            here.seen = True;
            for e in [edge here ->:Road:->] { self.tolls += e.toll; }
            for e in [edge here ->:Ferry:->] { self.fares += e.fare; }
            visit [-->];
        }
    }
}

def mode_cost_split(spec: dict) -> list {
    reg: dict = {};
    reg[spec["start"]] = Port(name=spec["start"]);
    for tr in spec["roads"] { for nm in [tr[0], tr[1]] { if nm not in reg { reg[nm] = Port(name=nm); } } }
    for tr in spec["ferries"] { for nm in [tr[0], tr[1]] { if nm not in reg { reg[nm] = Port(name=nm); } } }
    for tr in spec["roads"] { reg[tr[0]] +>:Road(toll=int(tr[2])):+> reg[tr[1]]; }
    for tr in spec["ferries"] { reg[tr[0]] +>:Ferry(fare=int(tr[2])):+> reg[tr[1]]; }
    wk = reg[spec["start"]] spawn CostAudit();
    return [wk.tolls, wk.fares];
}

with entry {
    print(mode_cost_split({'roads': [['a', 'b', 3], ['b', 'c', 4]], 'ferries': [['a', 'd', 2]], 'start': 'a'}));
}
