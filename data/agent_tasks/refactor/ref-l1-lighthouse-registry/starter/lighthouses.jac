"""Lighthouse registry: Lamp nodes on root, each with its Keeper nodes attached."""

node Lamp {
    has station: str;
    has burn_hours: float = 0.0;
    has rated_hours: float = 1000.0;
    has lit: bool = True;
}

node Keeper {
    has name: str;
    has on_duty: bool = True;
}

def _lamp(station: str) -> Lamp | None {
    for n in [root -->] {
        if isinstance(n, Lamp) and n.station == station {
            return n;
        }
    }
    return None;
}

def add_lamp(station: str, rated_hours: float) -> bool {
    if _lamp(station) is not None {
        return False;
    }
    root ++> Lamp(station=station, rated_hours=rated_hours);
    return True;
}

def assign_keeper(station: str, name: str) -> bool {
    lamp = _lamp(station);
    if lamp is None {
        return False;
    }
    lamp ++> Keeper(name=name);
    return True;
}

def douse(station: str) -> bool {
    lamp = _lamp(station);
    if lamp is None or not lamp.lit {
        return False;
    }
    lamp.lit = False;
    return True;
}

def log_night(hours: float) -> int {
    burned = 0;
    for n in [root -->] {
        if isinstance(n, Lamp) and n.lit {
            n.burn_hours += hours;
            burned += 1;
        }
    }
    return burned;
}

def due_for_bulb() -> list[str] {
    out: list[str] = [];
    for n in [root -->] {
        if isinstance(n, Lamp) and n.lit and n.burn_hours >= 0.9 * n.rated_hours {
            out.append(n.station);
        }
    }
    return sorted(out);
}

def keepers_at(station: str) -> list[str] {
    lamp = _lamp(station);
    out: list[str] = [];
    if lamp is None {
        return out;
    }
    for n in [lamp -->] {
        if isinstance(n, Keeper) and n.on_duty {
            out.append(n.name);
        }
    }
    return sorted(out);
}
