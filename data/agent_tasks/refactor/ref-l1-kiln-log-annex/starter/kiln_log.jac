"""Ceramics kiln log: firings, their losses and per-cone yield summaries."""

obj Firing {
    has batch: str;
    has cone: int;
    has pieces: int;
    has cracked: int = 0;
    has glaze_faults: int = 0;
    has aborted: bool = False;

    def losses -> int {
        return self.cracked + self.glaze_faults;
    }

    def yield_pct -> int {
        if self.aborted or self.pieces == 0 {
            return 0;
        }
        return (self.pieces - self.losses()) * 100 // self.pieces;
    }

    def abort -> bool {
        if self.aborted {
            return False;
        }
        self.aborted = True;
        return True;
    }
}

def firing_line(f: Firing) -> str {
    if f.aborted {
        return f"{f.batch} (cone {f.cone}): aborted";
    }
    return f"{f.batch} (cone {f.cone}): {f.yield_pct()}% of {f.pieces}";
}

def cone_yield(firings: list[Firing], cone: int) -> int {
    pieces = 0;
    lost = 0;
    for f in firings {
        if f.cone == cone and not f.aborted {
            pieces += f.pieces;
            lost += f.losses();
        }
    }
    if pieces == 0 {
        return 0;
    }
    return (pieces - lost) * 100 // pieces;
}

def worst_batch(firings: list[Firing]) -> str {
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
