walker Doubler { has picked: list = []; }

node Slot {
    has q: int;
    can serve with Doubler entry {
        visitor.picked.append(self.q * 2);
        visit [-->];
    }
}

def doubled_chain_values(spec: dict) -> list {
    slots: list = [];
    for raw in spec["values"] {
        cell = Slot(q=int(raw));
        slots.append(cell);
        if len(slots) > 1 { slots[-2] ++> cell; }
    }
    if not slots { return []; }
    runner = slots[0] spawn Doubler();
    return runner.picked;
}

with entry {
    print(doubled_chain_values({'values': [3, 1, 4]}));
}
