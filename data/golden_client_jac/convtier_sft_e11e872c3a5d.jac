node Cell { has charge: int; has swept: bool = False; }

walker ChargeScan {
    has pos: int = 0;
    has total: int = 0;
    has frac: float = 0.0;
    can sweep with Cell entry {
        if not here.swept {
            here.swept = True;
            self.total += 1;
            if here.charge > 0 { self.pos += 1; }
            visit [-->];
        }
    }
    can settle with exit {
        self.frac = round(self.pos / self.total, 2);
    }
}

def positive_fraction(spec: dict) -> float {
    adj: dict = dict(spec["adj"]); vals: dict = dict(spec["vals"]);
    cells: dict = {};
    for nm in vals.keys() { cells[nm] = Cell(charge=int(vals[nm])); }
    for (a, bs) in adj.items() { for b in bs { cells[a] ++> cells[b]; } }
    return (cells[str(spec["start"])] spawn ChargeScan()).frac;
}

with entry {
    print(positive_fraction({'adj': {'a': ['b', 'c'], 'b': [], 'c': []}, 'vals': {'a': 2, 'b': -1, 'c': 5}, 'start': 'a'}));
}
