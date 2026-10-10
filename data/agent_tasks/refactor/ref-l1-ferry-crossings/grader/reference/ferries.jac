"""Island ferry network: Port nodes on root, one-way crossings between ports."""

node Port {
    has name: str;
}

edge Crossing: Port --> Port {
    has minutes: int;
}

def _port(name: str) -> Port | None {
    wanted = name;
    found = [root -->[?:Port, name == wanted]];
    return found[0] if found else None;
}

def _crossing(src: str, dst: str) -> Crossing | None {
    a = _port(src);
    b = _port(dst);
    if a is None or b is None {
        return None;
    }
    found = [edge a ->:Crossing:-> b];
    return found[0] if found else None;
}

def add_port(name: str) -> bool {
    if _port(name) is not None {
        return False;
    }
    root ++> Port(name=name);
    return True;
}

def add_crossing(src: str, dst: str, minutes: int) -> bool {
    a = _port(src);
    b = _port(dst);
    if a is None or b is None or _crossing(src, dst) is not None {
        return False;
    }
    a +>:Crossing(minutes=minutes):+> b;
    return True;
}

def crossing_time(src: str, dst: str) -> int {
    c = _crossing(src, dst);
    return c.minutes if c is not None else -1;
}

def retime(src: str, dst: str, minutes: int) -> bool {
    c = _crossing(src, dst);
    if c is None {
        return False;
    }
    c.minutes = minutes;
    return True;
}

def quick_hops(src: str, limit: int) -> list[str] {
    a = _port(src);
    if a is None {
        return [];
    }
    return sorted([p.name for p in [a ->:Crossing:minutes <= limit:->]]);
}
