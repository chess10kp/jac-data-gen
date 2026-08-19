node Door { has charge: int; has open: bool = False; }

walker Inspector {
    has key: int;
    can inspect with Door entry {
        if here.charge >= self.key { here.open = True; }
        visit [-->];
    }
}

walker Runner {
    has passed: int = 0;
    can run with Door entry {
        if here.open {
            self.passed += 1;
            visit [-->];
        }
    }
}

def open_gate_run(spec: dict) -> int {
    charges: list = list(spec["charges"]);
    if not charges { return 0; }
    doors: list = [Door(charge=int(v)) for v in charges];
    for (a, b) in zip(doors, doors[1:]) { a ++> b; }
    inspector = doors[0] spawn Inspector(key=int(spec["key"]));
    return (doors[0] spawn Runner()).passed;
}

with entry {
    print(open_gate_run({'charges': [5, 3, 6], 'key': 4}));
}
