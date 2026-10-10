"""Garage state: spots, parked cars and takings kept in one record."""

node GarageState {
    has spots: dict[str, dict[str, any]] = {};
    has parked: dict[str, dict[str, any]] = {};
    has takings: dict[str, int] = {};
}

def state() -> GarageState {
    for n in [root -->] {
        if isinstance(n, GarageState) {
            return n;
        }
    }
    g = GarageState();
    root ++> g;
    return g;
}

def spot_taken(g: GarageState, code: str) -> bool {
    for plate in g.parked {
        if g.parked[plate]["spot"] == code {
            return True;
        }
    }
    return False;
}

"""Free spot of one kind on the lowest level (ties by spot code), or ""."""
def best_free(g: GarageState, kind: str) -> str {
    best = "";
    best_level = 0;
    for code in g.spots {
        s = g.spots[code];
        if s["kind"] != kind or spot_taken(g, code) {
            continue;
        }
        if best == "" or s["level"] < best_level or (s["level"] == best_level and code < best) {
            best = code;
            best_level = s["level"];
        }
    }
    return best;
}

"""First 30 minutes free, then 200 cents per started hour."""
def fee_for(minutes: int) -> int {
    if minutes <= 30 {
        return 0;
    }
    return 200 * ((minutes + 59) // 60);
}
