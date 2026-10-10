impl find_sailing(code: str) -> Sailing | None {
    wanted = code;
    found = [root -->[?:Sailing, code == wanted]];
    return found[0] if found else None;
}

impl locate(ref: str) -> LocateBooking {
    return root spawn LocateBooking(ref=ref);
}

impl add_sailing(code: str, day: int, lanes: int, seats: int) -> bool {
    if find_sailing(code) is not None {
        return False;
    }
    root ++> Sailing(code=code, day=day, lanes=lanes, seats=seats);
    return True;
}

impl book(sailing: str, ref: str, vehicle: str, passengers: int) -> str {
    s = find_sailing(sailing);
    if s is None {
        return "unknown sailing";
    }
    if locate(ref).found is not None {
        return "duplicate ref";
    }
    v = vehicle_named(vehicle);
    if v is None or passengers < 1 {
        return "bad booking";
    }
    b = Booking(ref=ref, vehicle=v, passengers=passengers);
    if not s.fits(b) {
        return "sold out";
    }
    s.take(b);
    return "ok";
}

impl cancel(ref: str) -> bool {
    b = locate(ref).found;
    if b is None {
        return False;
    }
    del b;
    return True;
}

impl move(ref: str, to_sailing: str) -> str {
    w = locate(ref);
    b = w.found;
    if b is None {
        return "unknown ref";
    }
    dst = find_sailing(to_sailing);
    if dst is None {
        return "unknown sailing";
    }
    if w.at == dst {
        return "ok";
    }
    if not dst.fits(b) {
        return "sold out";
    }
    del [edge b <-:Holds:<-];
    dst.take(b);
    return "ok";
}

impl manifest(sailing: str) -> list[str] {
    s = find_sailing(sailing);
    if s is None {
        return [];
    }
    return sorted([b.ref for b in [s ->:Holds:->]]);
}

impl free_space(sailing: str) -> list[int] {
    s = find_sailing(sailing);
    if s is None {
        return [0, 0];
    }
    return [s.free_lanes(), s.free_seats()];
}

impl day_passengers(day: int) -> int {
    return (root spawn DayCount(day=day)).total;
}
