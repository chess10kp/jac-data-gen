impl Firing.losses -> int {
    return self.cracked + self.glaze_faults;
}

impl Firing.yield_pct -> int {
    if self.aborted or self.pieces == 0 {
        return 0;
    }
    return (self.pieces - self.losses()) * 100 // self.pieces;
}

impl Firing.abort -> bool {
    if self.aborted {
        return False;
    }
    self.aborted = True;
    return True;
}

impl firing_line(f: Firing) -> str {
    if f.aborted {
        return f"{f.batch} (cone {f.cone}): aborted";
    }
    return f"{f.batch} (cone {f.cone}): {f.yield_pct()}% of {f.pieces}";
}

impl cone_yield(firings: list[Firing], cone: int) -> int {
    fired = [f for f in firings if f.cone == cone and not f.aborted];
    pieces = sum([f.pieces for f in fired]);
    if pieces == 0 {
        return 0;
    }
    return (pieces - sum([f.losses() for f in fired])) * 100 // pieces;
}

impl worst_batch(firings: list[Firing]) -> str {
    worst = "";
    worst_pct = 101;
    for f in firings {
        if not f.aborted and f.pieces > 0 and f.yield_pct() < worst_pct {
            worst = f.batch;
            worst_pct = f.yield_pct();
        }
    }
    return worst;
}
