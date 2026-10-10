"""Island ferry reservations: sailings with deck lanes and passenger seats."""

import from fleet { fleet, used, fits }

def add_sailing(code: str, day: int, lanes: int, seats: int) -> bool {
    f = fleet();
    if code in f.sailings {
        return False;
    }
    f.sailings[code] = {"day": day, "lanes": lanes, "seats": seats};
    return True;
}

def book(sailing: str, ref: str, vehicle: str, passengers: int) -> str {
    f = fleet();
    if sailing not in f.sailings {
        return "unknown sailing";
    }
    if ref in f.bookings {
        return "duplicate ref";
    }
    if vehicle not in ["foot", "car", "van"] or passengers < 1 {
        return "bad booking";
    }
    if not fits(f, sailing, vehicle, passengers) {
        return "sold out";
    }
    f.bookings[ref] = {"sailing": sailing, "vehicle": vehicle, "passengers": passengers};
    return "ok";
}

def cancel(ref: str) -> bool {
    f = fleet();
    if ref not in f.bookings {
        return False;
    }
    f.bookings.pop(ref);
    return True;
}

def move(ref: str, to_sailing: str) -> str {
    f = fleet();
    if ref not in f.bookings {
        return "unknown ref";
    }
    if to_sailing not in f.sailings {
        return "unknown sailing";
    }
    b = f.bookings[ref];
    if b["sailing"] == to_sailing {
        return "ok";
    }
    if not fits(f, to_sailing, b["vehicle"], b["passengers"]) {
        return "sold out";
    }
    b["sailing"] = to_sailing;
    return "ok";
}

def manifest(sailing: str) -> list[str] {
    f = fleet();
    refs: list[str] = [];
    for ref in f.bookings {
        if f.bookings[ref]["sailing"] == sailing {
            refs.append(ref);
        }
    }
    return sorted(refs);
}

def free_space(sailing: str) -> list[int] {
    f = fleet();
    if sailing not in f.sailings {
        return [0, 0];
    }
    u = used(f, sailing);
    s = f.sailings[sailing];
    return [s["lanes"] - u[0], s["seats"] - u[1]];
}

def day_passengers(day: int) -> int {
    f = fleet();
    total = 0;
    for ref in f.bookings {
        b = f.bookings[ref];
        if f.sailings[b["sailing"]]["day"] == day {
            total += b["passengers"];
        }
    }
    return total;
}
