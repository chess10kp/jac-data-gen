walker Booster { has cut: int; has bonus: int; }

node Worker {
    has pay: int;
    has bumped: bool = False;
    has polled: bool = False;
    can bump with Booster entry {
        if not self.bumped {
            self.bumped = True;
            if self.pay >= visitor.cut { self.pay += visitor.bonus; }
            visit [-->];
        }
    }
}

walker Payroll {
    has total: int = 0;
    has count: int = 0;
    has avg: float = 0.0;
    can poll with Worker entry {
        if not here.polled {
            here.polled = True;
            self.total += here.pay;
            self.count += 1;
            visit [-->];
        }
    }
    can settle with exit {
        self.avg = round(self.total / self.count, 2);
    }
}

def avg_after_boost(spec: dict) -> float {
    adj: dict = dict(spec["adj"]); vals: dict = dict(spec["vals"]);
    crew: dict = {};
    for nm in vals.keys() { crew[nm] = Worker(pay=int(vals[nm])); }
    for (a, bs) in adj.items() { for b in bs { crew[a] ++> crew[b]; } }
    base = crew[str(spec["start"])];
    booster = base spawn Booster(cut=int(spec["cut"]), bonus=int(spec["bonus"]));
    return (base spawn Payroll()).avg;
}

with entry {
    print(avg_after_boost({'adj': {'a': ['b', 'c'], 'b': [], 'c': []}, 'vals': {'a': 4, 'b': 10, 'c': 2}, 'start': 'a', 'cut': 5, 'bonus': 3}));
}
