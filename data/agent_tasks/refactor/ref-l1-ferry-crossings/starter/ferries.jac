"""Island ferry network: Port nodes on root, one-way crossings between ports."""

node Port {
    has name: str;
}

node Timetable {
    has minutes: dict[str, int] = {};
}

def _port(name: str) -> Port | None {
    wanted = name;
    found = [root -->[?:Port, name == wanted]];
    return found[0] if found else None;
}

def _timetable() -> Timetable {
    found = [root -->[?:Timetable]];
    if found {
        return found[0];
    }
    t = Timetable();
    root ++> t;
    return t;
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
    key = f"{src}->{dst}";
    tt = _timetable();
    if a is None or b is None or key in tt.minutes {
        return False;
    }
    a ++> b;
    tt.minutes[key] = minutes;
    return True;
}

def crossing_time(src: str, dst: str) -> int {
    return _timetable().minutes.get(f"{src}->{dst}", -1);
}

def retime(src: str, dst: str, minutes: int) -> bool {
    tt = _timetable();
    key = f"{src}->{dst}";
    if key not in tt.minutes {
        return False;
    }
    tt.minutes[key] = minutes;
    return True;
}

def quick_hops(src: str, limit: int) -> list[str] {
    a = _port(src);
    if a is None {
        return [];
    }
    tt = _timetable();
    return sorted([p.name for p in [a -->[?:Port]] if tt.minutes[f"{src}->{p.name}"] <= limit]);
}
