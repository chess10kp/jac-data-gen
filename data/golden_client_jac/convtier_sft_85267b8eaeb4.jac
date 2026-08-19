node Sensor { has name: str; has temp: int; has polled: bool = False; }

walker Mean {
    has cutoff: int;
    has total: int = 0;
    has cnt: int = 0;
    can poll with Sensor entry {
        if not here.polled {
            here.polled = True;
            if here.temp > self.cutoff { self.total += here.temp; self.cnt += 1; }
            visit [-->];
        }
    }
}

def avg_over_threshold(spec: dict) -> float {
    adj: dict = spec["adj"]; vals: dict = spec["vals"];
    grid: dict = {};
    for key in adj.keys() { grid[key] = Sensor(name=key, temp=vals[key]); }
    for ends in adj.values() { for e in ends { if e not in grid { grid[e] = Sensor(name=e, temp=vals[e]); } } }
    for (a, ends) in adj.items() { for e in ends { grid[a] ++> grid[e]; } }
    m = grid[spec["start"]] spawn Mean(cutoff=spec["cutoff"]);
    if m.cnt == 0 { return 0.0; }
    return m.total / m.cnt;
}

with entry {
    print(avg_over_threshold({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'vals': {'a': 4, 'b': 8, 'c': 9, 'd': 2}, 'start': 'a', 'cutoff': 5}));
}
