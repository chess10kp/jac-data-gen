"""Tram network: Stop nodes on root, Track edges (from -> to) tagged by line."""

node Stop {
    has name: str;
}

edge Track: Stop --> Stop {
    has line: str;
    has minutes: int = 2;
}

def stop(label: str) -> Stop {
    found = [root -->[?:Stop, name == label]];
    if found {
        return found[0];
    }
    return root ++> Stop(name=label);
}

def add_hop(line: str, a: str, b: str, minutes: int) {
    stop(a) +>:Track(line=line, minutes=minutes):+> stop(b);
}
