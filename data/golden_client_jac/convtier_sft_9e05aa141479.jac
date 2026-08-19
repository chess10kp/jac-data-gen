walker LevelPick { has bag: list = []; }

node Meter {
    has level: float;
    has done: bool = False;
    can share with LevelPick entry {
        if not self.done {
            self.done = True;
            visitor.bag.append(self.level);
            visit [-->];
        }
    }
}

def sorted_reachable_vals(spec: dict) -> list {
    meters: dict = {k: Meter(level=float(v)) for (k, v) in spec["vals"].items()};
    for (frm, tos) in spec["adj"].items() {
        for t in tos { meters[frm] ++> meters[t]; }
    }
    picker = meters[str(spec["start"])] spawn LevelPick();
    return sorted(picker.bag);
}

with entry {
    print(sorted_reachable_vals({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'vals': {'a': 1.5, 'b': 0.25, 'c': 3.0, 'd': 2.5}, 'start': 'a'}));
}
