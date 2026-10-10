"""Tram network: Stop nodes on root, Track edges tagged with the line and the minutes per hop.

A line never branches: each stop has at most one outgoing hop per line.
"""

node Stop {
    has name: str;
}

edge Track: Stop --> Stop {
    has line: str;
    has minutes: int;
}

"""Spawned on a stop: rides one line until it ends or comes back to a stop already passed."""
walker Ride {
    has line: str;
    has route: list[str] = [];
    has minutes: int = 0;
    has looped: bool = False;

    can step with Stop entry {
        if here.name in self.route {
            self.looped = True;
            disengage;
        }
        self.route.append(here.name);
        ln = self.line;
        for hop in [edge here ->:Track:line == ln:->] {
            self.minutes += hop.minutes;
        }
        visit [here ->:Track:line == ln:->];
    }
}

def find_stop(label: str) -> Stop | None {
    found = [root -->[?:Stop, name == label]];
    return found[0] if found else None;
}

def stop(label: str) -> Stop {
    s = find_stop(label);
    if s is None {
        s = Stop(name=label);
        root ++> s;
    }
    return s;
}

def add_hop(line: str, a: str, b: str, minutes: int) -> bool {
    if a == b or minutes <= 0 {
        return False;
    }
    src = stop(a);
    ln = line;
    if [src ->:Track:line == ln:->] {
        return False;
    }
    src +>:Track(line=line, minutes=minutes):+> stop(b);
    return True;
}

def run(line: str, start: str) -> Ride {
    s = find_stop(start);
    if s is None {
        return Ride(line=line);
    }
    return s spawn Ride(line=line);
}

def ride(line: str, start: str) -> list[str] {
    return run(line, start).route;
}

def ride_minutes(line: str, start: str) -> int {
    return run(line, start).minutes;
}

def is_loop(line: str, start: str) -> bool {
    return run(line, start).looped;
}
