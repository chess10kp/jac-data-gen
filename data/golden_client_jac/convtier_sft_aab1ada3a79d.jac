node Farm { has crop: int; has tallied: bool = False; has judged: bool = False; }

walker CropSum {
    has total: int = 0;
    has count: int = 0;
    can tally with Farm entry {
        if not here.tallied {
            here.tallied = True;
            self.total += here.crop;
            self.count += 1;
            visit [-->];
        }
    }
}

walker OverBar {
    has bar: float;
    has hits: int = 0;
    can judge with Farm entry {
        if not here.judged {
            here.judged = True;
            if here.crop > self.bar { self.hits += 1; }
            visit [-->];
        }
    }
}

def above_average_count(spec: dict) -> int {
    adj: dict = dict(spec["adj"]); vals: dict = dict(spec["vals"]);
    farms: dict = {};
    for nm in vals.keys() { farms[nm] = Farm(crop=int(vals[nm])); }
    for (a, bs) in adj.items() { for b in bs { farms[a] ++> farms[b]; } }
    origin = farms[str(spec["start"])];
    first = origin spawn CropSum();
    bar: float = first.total / first.count;
    return (origin spawn OverBar(bar=bar)).hits;
}

with entry {
    print(above_average_count({'adj': {'a': ['b', 'c'], 'b': [], 'c': []}, 'vals': {'a': 1, 'b': 5, 'c': 3}, 'start': 'a'}));
}
