"""Boarding kennel desk: runs of a given size, dog stays booked into runs, billing.

A stay covers nights start .. start + nights - 1. A dog fits any run of its size
or larger; the nightly price is fixed at booking time.
"""

node Kennel {
    has runs: dict[str, dict[str, any]] = {};
    has stays: list[dict[str, any]] = [];
}

def _kennel() -> Kennel {
    for n in [root -->] {
        if isinstance(n, Kennel) {
            return n;
        }
    }
    k = Kennel();
    root ++> k;
    return k;
}

def _rank(size: str) -> int {
    order = ["small", "medium", "large"];
    if size not in order {
        return -1;
    }
    return order.index(size);
}

def _overlaps(stay: dict[str, any], start: int, nights: int) -> bool {
    return stay["start"] < start + nights and start < stay["start"] + stay["nights"];
}

def _run_free(k: Kennel, code: str, start: int, nights: int) -> bool {
    for s in k.stays {
        if s["run"] == code and _overlaps(s, start, nights) {
            return False;
        }
    }
    return True;
}

def add_run(code: str, size: str, nightly: int) -> bool {
    k = _kennel();
    if code in k.runs or _rank(size) < 0 or nightly < 0 {
        return False;
    }
    k.runs[code] = {"size": size, "nightly": nightly};
    return True;
}

def reprice(code: str, nightly: int) -> bool {
    k = _kennel();
    if code not in k.runs or nightly < 0 {
        return False;
    }
    k.runs[code]["nightly"] = nightly;
    return True;
}

def book(dog: str, size: str, start: int, nights: int) -> str {
    k = _kennel();
    need = _rank(size);
    if need < 0 or nights < 1 {
        return "";
    }
    best = "";
    best_rank = 99;
    for code in k.runs {
        r = _rank(k.runs[code]["size"]);
        if r < need or not _run_free(k, code, start, nights) {
            continue;
        }
        if r < best_rank or (r == best_rank and code < best) {
            best = code;
            best_rank = r;
        }
    }
    if best == "" {
        return "";
    }
    k.stays.append({"run": best, "dog": dog, "start": start, "nights": nights,
                    "nightly": k.runs[best]["nightly"]});
    return best;
}

def check_out(dog: str) -> int {
    k = _kennel();
    keep: list[dict[str, any]] = [];
    removed = 0;
    for s in k.stays {
        if s["dog"] == dog {
            removed += 1;
        } else {
            keep.append(s);
        }
    }
    k.stays = keep;
    return removed;
}

def occupancy(night: int) -> list[str] {
    k = _kennel();
    lines: list[str] = [];
    for s in k.stays {
        if _overlaps(s, night, 1) {
            lines.append(s["run"] + ":" + s["dog"]);
        }
    }
    return sorted(lines);
}

def free_runs(size: str, start: int, nights: int) -> int {
    k = _kennel();
    need = _rank(size);
    if need < 0 {
        return 0;
    }
    count = 0;
    for code in k.runs {
        if _rank(k.runs[code]["size"]) >= need and _run_free(k, code, start, nights) {
            count += 1;
        }
    }
    return count;
}

def bill(dog: str) -> int {
    k = _kennel();
    total = 0;
    for s in k.stays {
        if s["dog"] == dog {
            total += s["nights"] * s["nightly"];
        }
    }
    return total;
}
