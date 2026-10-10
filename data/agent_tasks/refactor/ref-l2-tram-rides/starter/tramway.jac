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

def _ride(line: str, start: str) -> dict[str, any] {
    route: list[str] = [];
    minutes = 0;
    looped = False;
    cur = find_stop(start);
    ln = line;
    while cur is not None {
        route.append(cur.name);
        hops = [edge cur ->:Track:line == ln:->];
        if len(hops) == 0 {
            break;
        }
        minutes += hops[0].minutes;
        nxt = [cur ->:Track:line == ln:->][0];
        if nxt.name in route {
            looped = True;
            break;
        }
        cur = nxt;
    }
    return {"route": route, "minutes": minutes, "looped": looped};
}

def ride(line: str, start: str) -> list[str] {
    return list(_ride(line, start)["route"]);
}

def ride_minutes(line: str, start: str) -> int {
    return int(_ride(line, start)["minutes"]);
}

def is_loop(line: str, start: str) -> bool {
    return bool(_ride(line, start)["looped"]);
}
