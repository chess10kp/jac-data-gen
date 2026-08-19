node Sensor { has sid: str; has reading: int; }

walker AvgReader {
    has seen: list = [];
    has readings: list = [];
    has mean: float = 0.0;
    can poll with Sensor entry {
        if here.sid in self.seen { return; }
        self.seen.append(here.sid);
        self.readings.append(here.reading);
        visit [-->];
    }
    can wrap with exit {
        self.mean = round(sum(self.readings) / len(self.readings), 2);
    }
}

def mean_reachable_val(spec: dict) -> float {
    vals: dict = dict(spec["vals"]);
    adj: dict = dict(spec["adj"]);
    grid: dict = {};
    for sid in vals.keys() { grid[sid] = Sensor(sid=str(sid), reading=int(vals[sid])); }
    for a in adj.keys() {
        for b in adj[a] { grid[a] ++> grid[b]; }
    }
    return (grid[str(spec["start"])] spawn AvgReader()).mean;
}

with entry {
    print(mean_reachable_val({'adj': {'a': ['b', 'c'], 'b': [], 'c': []}, 'vals': {'a': 3, 'b': 4, 'c': 6}, 'start': 'a'}));
}
