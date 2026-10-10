"""Film production call sheets: crew report a department-specific time before their first scene of the day."""

node Production {
    has crew: dict[str, str] = {};
    has scenes: dict[str, dict[str, any]] = {};
    has assignments: list[dict[str, any]] = [];
}

def _production -> Production {
    for n in [root -->] {
        if isinstance(n, Production) {
            return n;
        }
    }
    p = Production();
    root ++> p;
    return p;
}

"""Minutes before their first scene that each department must be on set."""
def prep_minutes(dept: str) -> int {
    if dept == "makeup" {
        return 120;
    }
    if dept == "wardrobe" {
        return 90;
    }
    if dept == "camera" {
        return 60;
    }
    return 30;
}

def clock(minutes: int) -> str {
    return f"{minutes // 60:02d}:{minutes % 60:02d}";
}

def hire(name: str, dept: str) -> bool {
    p = _production();
    if name in p.crew {
        return False;
    }
    if dept not in ["camera", "sound", "makeup", "wardrobe", "grip"] {
        return False;
    }
    p.crew[name] = dept;
    return True;
}

"""start is "HH:MM"."""
def add_scene(day: int, number: str, start: str, location: str) -> bool {
    p = _production();
    if number in p.scenes {
        return False;
    }
    parts = start.split(":");
    p.scenes[number] = {"day": day, "start": int(parts[0]) * 60 + int(parts[1]), "location": location};
    return True;
}

"""Put a crew member on a scene; early = extra minutes they need on top of their department's prep."""
def assign(name: str, scene: str, early: int = 0) -> bool {
    p = _production();
    if name not in p.crew or scene not in p.scenes {
        return False;
    }
    for a in p.assignments {
        if a["name"] == name and a["scene"] == scene {
            return False;
        }
    }
    p.assignments.append({"name": name, "scene": scene, "early": early});
    return True;
}

"""Lines "HH:MM Name (DEPT)" for everyone working that day, by call time then name."""
def call_sheet(day: int) -> list[str] {
    p = _production();
    best: dict[str, int] = {};
    for a in p.assignments {
        sc = p.scenes[a["scene"]];
        if sc["day"] != day {
            continue;
        }
        t = sc["start"] - prep_minutes(p.crew[a["name"]]) - a["early"];
        if a["name"] not in best or t < best[a["name"]] {
            best[a["name"]] = t;
        }
    }
    rows: list[str] = [];
    for row in sorted([f"{best[n]:05d} {n}" for n in best]) {
        name = row.split(" ", 1)[1];
        rows.append(f"{clock(best[name])} {name} ({p.crew[name].upper()})");
    }
    return rows;
}

def locations(day: int) -> list[str] {
    p = _production();
    out: list[str] = [];
    for number in p.scenes {
        loc = p.scenes[number]["location"];
        if p.scenes[number]["day"] == day and loc not in out {
            out.append(loc);
        }
    }
    return sorted(out);
}

def crew_days(name: str) -> list[int] {
    p = _production();
    days: list[int] = [];
    for a in p.assignments {
        if a["name"] == name {
            d = p.scenes[a["scene"]]["day"];
            if d not in days {
                days.append(d);
            }
        }
    }
    return sorted(days);
}

"""Crew in a department who have no scene at all yet."""
def idle(dept: str) -> list[str] {
    p = _production();
    busy: list[str] = [a["name"] for a in p.assignments];
    return sorted([n for n in p.crew if p.crew[n] == dept and n not in busy]);
}
