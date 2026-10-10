"""Greenhouse watering rounds: beds of plants, each with its own watering interval and growth stage."""

node Greenhouse {
    has beds: list[str] = [];
    has plants: dict[str, dict[str, any]] = {};
}

def _house() -> Greenhouse {
    for n in [root -->] {
        if isinstance(n, Greenhouse) {
            return n;
        }
    }
    g = Greenhouse();
    root ++> g;
    return g;
}

def add_bed(code: str) -> bool {
    g = _house();
    if code in g.beds {
        return False;
    }
    g.beds.append(code);
    return True;
}

def plant(bed: str, tag: str, species: str, interval_days: int, day: int) -> bool {
    g = _house();
    if bed not in g.beds or tag in g.plants {
        return False;
    }
    g.plants[tag] = {
        "bed": bed,
        "species": species,
        "interval": interval_days,
        "last": day,
        "planted": day,
        "stage": "seedling"
    };
    return True;
}

def promote(tag: str) -> str {
    g = _house();
    if tag not in g.plants {
        return "";
    }
    p = g.plants[tag];
    if p["stage"] == "seedling" {
        p["stage"] = "growing";
    } elif p["stage"] == "growing" {
        p["stage"] = "mature";
    }
    return p["stage"];
}

def water_bed(bed: str, day: int) -> int {
    g = _house();
    n = 0;
    for tag in g.plants {
        if g.plants[tag]["bed"] == bed {
            g.plants[tag]["last"] = day;
            n += 1;
        }
    }
    return n;
}

def due_on(day: int) -> list[str] {
    g = _house();
    out: list[str] = [];
    for tag in g.plants {
        p = g.plants[tag];
        gap = p["interval"];
        if p["stage"] == "seedling" {
            gap = 1;
        }
        if day - p["last"] >= gap {
            out.append(f"{p['bed']}/{tag}");
        }
    }
    return sorted(out);
}

def uproot(tag: str) -> bool {
    g = _house();
    if tag not in g.plants {
        return False;
    }
    g.plants.pop(tag);
    return True;
}

def age(tag: str, day: int) -> int {
    g = _house();
    if tag not in g.plants {
        return -1;
    }
    return day - g.plants[tag]["planted"];
}
