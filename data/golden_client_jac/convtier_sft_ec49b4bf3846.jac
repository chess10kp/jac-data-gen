node Relay { has name: str; has depth: int = -1; has stamped: bool = False; has probed: bool = False; }

walker FarSeek {
    has far_name: str = "";
    has far_depth: int = -1;
    can roam with Relay entry {
        if not here.stamped {
            here.stamped = True;
            for nxt in [-->] {
                if nxt.depth == -1 { nxt.depth = here.depth + 1; }
            }
            if here.depth > self.far_depth or (here.depth == self.far_depth and here.name < self.far_name) {
                self.far_name = here.name;
                self.far_depth = here.depth;
            }
            visit [-->];
        }
    }
}

walker SpanCount {
    has count: int = 0;
    can probe with Relay entry {
        if not here.probed {
            here.probed = True;
            self.count += 1;
            visit [-->];
        }
    }
}

def far_probe_pair(spec: dict) -> list {
    adj: dict = dict(spec["adj"]);
    relays: dict = {};
    for nm in adj.keys() { relays[nm] = Relay(name=str(nm)); }
    for (a, bs) in adj.items() { for b in bs { relays[a] ++> relays[b]; } }
    base = relays[str(spec["start"])];
    base.depth = 0;
    seeker = base spawn FarSeek();
    probe = relays[seeker.far_name] spawn SpanCount();
    return [seeker.far_name, probe.count];
}

with entry {
    print(far_probe_pair({'adj': {'s': ['a', 'b'], 'a': ['c'], 'b': [], 'c': []}, 'start': 's'}));
}
