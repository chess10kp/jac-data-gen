"""Ferry state store: every sailing and booking lives in one Fleet record."""

node Fleet {
    has sailings: dict[str, dict[str, int]] = {};
    has bookings: dict[str, dict[str, any]] = {};
}

def fleet() -> Fleet {
    for n in [root -->] {
        if isinstance(n, Fleet) {
            return n;
        }
    }
    f = Fleet();
    root ++> f;
    return f;
}

"""Deck lanes a booking needs: van 2, car 1, foot 0."""
def lanes_for(vehicle: str) -> int {
    if vehicle == "van" {
        return 2;
    }
    if vehicle == "car" {
        return 1;
    }
    return 0;
}

"""Seats a booking needs: foot passengers take seats, vehicle passengers stay in the vehicle."""
def seats_for(vehicle: str, passengers: int) -> int {
    if vehicle == "foot" {
        return passengers;
    }
    return 0;
}

def used(f: Fleet, sailing: str) -> list[int] {
    lanes = 0;
    seats = 0;
    for ref in f.bookings {
        b = f.bookings[ref];
        if b["sailing"] == sailing {
            lanes += lanes_for(b["vehicle"]);
            seats += seats_for(b["vehicle"], b["passengers"]);
        }
    }
    return [lanes, seats];
}

def fits(f: Fleet, sailing: str, vehicle: str, passengers: int) -> bool {
    u = used(f, sailing);
    s = f.sailings[sailing];
    return u[0] + lanes_for(vehicle) <= s["lanes"] and u[1] + seats_for(vehicle, passengers) <= s["seats"];
}
