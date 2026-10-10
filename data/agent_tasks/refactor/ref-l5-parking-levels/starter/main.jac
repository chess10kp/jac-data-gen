"""Multi-level parking garage with standard and EV charging spots.

Times are minutes since opening. Fees are in cents.
"""

import from store { state, spot_taken, best_free, fee_for }

def add_spot(code: str, level: int, kind: str) -> bool {
    g = state();
    if code in g.spots or kind not in ["standard", "ev"] {
        return False;
    }
    g.spots[code] = {"level": level, "kind": kind};
    if str(level) not in g.takings {
        g.takings[str(level)] = 0;
    }
    return True;
}

def park(plate: str, at: int, wants_ev: bool) -> str {
    g = state();
    p = plate.strip().upper();
    if p in g.parked {
        return "";
    }
    spot = "";
    if wants_ev {
        spot = best_free(g, "ev");
    }
    if spot == "" {
        spot = best_free(g, "standard");
    }
    if spot == "" {
        return "";
    }
    g.parked[p] = {"spot": spot, "since": at};
    return spot;
}

def where(plate: str) -> str {
    g = state();
    p = plate.strip().upper();
    if p not in g.parked {
        return "";
    }
    return g.parked[p]["spot"];
}

def leave(plate: str, at: int) -> int {
    g = state();
    p = plate.strip().upper();
    if p not in g.parked {
        return -1;
    }
    rec = g.parked[p];
    if at < rec["since"] {
        return -1;
    }
    fee = fee_for(at - rec["since"]);
    lvl = str(g.spots[rec["spot"]]["level"]);
    g.takings[lvl] = g.takings[lvl] + fee;
    g.parked.pop(p);
    return fee;
}

def level_free(level: int) -> int {
    g = state();
    free = 0;
    for code in g.spots {
        if g.spots[code]["level"] == level and not spot_taken(g, code) {
            free += 1;
        }
    }
    return free;
}

def takings(level: int) -> int {
    g = state();
    return g.takings.get(str(level), 0);
}
