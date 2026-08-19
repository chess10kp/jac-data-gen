node Gauge { has v: int; }

walker PeakTrail {
    has trail: list = [];
    can note with Gauge entry {
        if not self.trail { self.trail.append(here.v); }
        elif here.v > self.trail[-1] { self.trail.append(here.v); }
        else { self.trail.append(self.trail[-1]); }
        visit [-->];
    }
}

def running_max_prefix(spec: dict) -> list {
    if len(spec["nums"]) == 0 { return []; }
    gauges: list = [Gauge(v=int(n)) for n in spec["nums"]];
    for i in range(1, len(gauges)) { gauges[i - 1] ++> gauges[i]; }
    hiker = gauges[0] spawn PeakTrail();
    return hiker.trail;
}

with entry {
    print(running_max_prefix({'nums': [3, 1, 4, 1, 5]}));
}
