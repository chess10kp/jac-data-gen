"""Drying shelves in a pottery studio: each shelf holds a limited number of pieces."""

node Studio {
    has shelves: dict[str, dict[str, any]] = {};
}

def _studio() -> Studio {
    for n in [root -->] {
        if isinstance(n, Studio) {
            return n;
        }
    }
    s = Studio();
    root ++> s;
    return s;
}

def add_shelf(name: str, capacity: int) -> bool {
    s = _studio();
    if name in s.shelves {
        return False;
    }
    s.shelves[name] = {"capacity": capacity, "pieces": []};
    return True;
}

def place_piece(shelf: str, maker: str, kg: float) -> bool {
    s = _studio();
    if shelf not in s.shelves {
        return False;
    }
    rec = s.shelves[shelf];
    if len(rec["pieces"]) >= rec["capacity"] {
        return False;
    }
    rec["pieces"].append({"maker": maker, "kg": kg});
    return True;
}

def shelf_load(shelf: str) -> float {
    s = _studio();
    if shelf not in s.shelves {
        return 0.0;
    }
    total = 0.0;
    for p in s.shelves[shelf]["pieces"] {
        total += p["kg"];
    }
    return total;
}

def shelves_holding(maker: str) -> list[str] {
    s = _studio();
    out: list[str] = [];
    for name in s.shelves {
        for p in s.shelves[name]["pieces"] {
            if p["maker"] == maker and name not in out {
                out.append(name);
            }
        }
    }
    return sorted(out);
}

def collect(maker: str) -> int {
    s = _studio();
    removed = 0;
    for name in s.shelves {
        keep: list[dict[str, any]] = [];
        for p in s.shelves[name]["pieces"] {
            if p["maker"] == maker {
                removed += 1;
            } else {
                keep.append(p);
            }
        }
        s.shelves[name]["pieces"] = keep;
    }
    return removed;
}

def free_slots() -> int {
    s = _studio();
    total = 0;
    for name in s.shelves {
        total += s.shelves[name]["capacity"] - len(s.shelves[name]["pieces"]);
    }
    return total;
}
