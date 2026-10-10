impl find_level(number: int) -> Level | None {
    wanted = number;
    found = [root -->[?:Level, number == wanted]];
    return found[0] if found else None;
}

impl locate(plate: str) -> LocateCar {
    return root spawn LocateCar(plate=plate.strip().upper());
}

impl add_spot(code: str, level: int, kind: str) -> bool {
    k = kind_named(kind);
    wanted = code;
    if k is None or [root -->[?:Level] ->:Contains:->[?:Spot, code == wanted]] {
        return False;
    }
    lv = find_level(level);
    if lv is None {
        lv = root ++> Level(number=level);
    }
    lv +>:Contains():+> Spot(code=code, kind=k);
    return True;
}

impl park(plate: str, at: int, wants_ev: bool) -> str {
    p = plate.strip().upper();
    if locate(p).car is not None {
        return "";
    }
    spot: Spot | None = None;
    if wants_ev {
        spot = (root spawn SpotFinder(kind=SpotKind.EV)).best;
    }
    if spot is None {
        spot = (root spawn SpotFinder(kind=SpotKind.STANDARD)).best;
    }
    if spot is None {
        return "";
    }
    spot +>:Occupied(since=at):+> Car(plate=p);
    return spot.code;
}

impl where(plate: str) -> str {
    s = locate(plate).spot;
    return s.code if s is not None else "";
}

impl leave(plate: str, at: int) -> int {
    w = locate(plate);
    car = w.car;
    spot = w.spot;
    lv = w.level;
    if car is None or spot is None or lv is None {
        return -1;
    }
    since = [edge spot ->:Occupied:->][0].since;
    if at < since {
        return -1;
    }
    fee = fee_for(at - since);
    lv.takings += fee;
    del car;
    return fee;
}

impl level_free(level: int) -> int {
    lv = find_level(level);
    if lv is None {
        return 0;
    }
    return len(lv.free_spots(SpotKind.STANDARD)) + len(lv.free_spots(SpotKind.EV));
}

impl takings(level: int) -> int {
    lv = find_level(level);
    return lv.takings if lv is not None else 0;
}
