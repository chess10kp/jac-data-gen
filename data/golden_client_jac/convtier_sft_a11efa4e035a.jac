node Town { has name: str; has worth: int; has toured: bool = False; }

walker PickChild {
    has stage: int = 0;
    has best_name: str = "";
    has best_val: int = 0;
    can pick with Town entry {
        if self.stage == 0 {
            self.stage = 1;
            visit [-->];
        } elif self.best_name == "" or here.worth > self.best_val or (here.worth == self.best_val and here.name < self.best_name) {
            self.best_name = here.name;
            self.best_val = here.worth;
        }
    }
}

walker TownCount {
    has count: int = 0;
    can tour with Town entry {
        if not here.toured {
            here.toured = True;
            self.count += 1;
            visit [-->];
        }
    }
}

def reach_from_max_child(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); vals: dict = dict(spec["vals"]);
    towns: dict = {};
    for nm in vals.keys() { towns[nm] = Town(name=str(nm), worth=int(vals[nm])); }
    for (a, bs) in adj.items() { for b in bs { towns[a] ++> towns[b]; } }
    picker = towns[str(spec["start"])] spawn PickChild();
    if picker.best_name == "" { return 0; }
    return (towns[picker.best_name] spawn TownCount()).count;
}

with entry {
    print(reach_from_max_child({'adj': {'h': ['a', 'b'], 'a': ['x'], 'b': ['y', 'z'], 'x': [], 'y': [], 'z': []}, 'vals': {'h': 0, 'a': 3, 'b': 7, 'x': 1, 'y': 1, 'z': 1}, 'start': 'h'}));
}
