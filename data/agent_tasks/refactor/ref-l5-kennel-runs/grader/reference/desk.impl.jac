impl find_run(code: str) -> Run | None {
    wanted = code;
    found = [root -->[?:Run, code == wanted]];
    return found[0] if found else None;
}

impl add_run(code: str, size: str, nightly: int) -> bool {
    s = size_named(size);
    if s is None or nightly < 0 or find_run(code) is not None {
        return False;
    }
    root ++> Run(code=code, size=s, nightly=nightly);
    return True;
}

impl reprice(code: str, nightly: int) -> bool {
    r = find_run(code);
    if r is None or nightly < 0 {
        return False;
    }
    r.nightly = nightly;
    return True;
}

impl book(dog: str, size: str, start: int, nights: int) -> str {
    s = size_named(size);
    if s is None or nights < 1 {
        return "";
    }
    w = root spawn PickRun(need=size_rank(s), start=start, nights=nights);
    r = w.best;
    if r is None {
        return "";
    }
    r +>:Hosts(nightly=r.nightly):+> Stay(dog=dog, start=start, nights=nights);
    return r.code;
}

impl check_out(dog: str) -> int {
    return (root spawn Departure(dog=dog)).removed;
}

impl occupancy(night: int) -> list[str] {
    return sorted((root spawn NightList(night=night)).lines);
}

impl free_runs(size: str, start: int, nights: int) -> int {
    s = size_named(size);
    if s is None {
        return 0;
    }
    need = size_rank(s);
    return len([r for r in [root -->[?:Run]] if r.rank() >= need and r.free_for(start, nights)]);
}

impl bill(dog: str) -> int {
    return (root spawn Billing(dog=dog)).total;
}
