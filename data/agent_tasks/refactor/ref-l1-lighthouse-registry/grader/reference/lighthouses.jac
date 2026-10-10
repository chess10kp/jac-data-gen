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
    wanted = station;
    found = [root -->[?:Lamp, station == wanted]];
    return found[0] if found else None;
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
    lamps = [root -->[?:Lamp, lit == True]];
    for lamp in lamps {
        lamp.burn_hours += hours;
    }
    return len(lamps);
}

def due_for_bulb() -> list[str] {
    return sorted([
        l.station for l in [root -->[?:Lamp, lit == True]]
        if l.burn_hours >= 0.9 * l.rated_hours
    ]);
}

def keepers_at(station: str) -> list[str] {
    lamp = _lamp(station);
    if lamp is None {
        return [];
    }
    return sorted([k.name for k in [lamp -->[?:Keeper, on_duty == True]]]);
}
