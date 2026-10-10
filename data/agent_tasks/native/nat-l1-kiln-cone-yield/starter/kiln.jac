"""Ceramics studio kiln log: one Firing node per load, on root."""

node Firing {
    has batch: str;
    has cone: int;            # pyrometric cone the load was fired to
    has pieces: int;
    has cracked: int = 0;
    has glaze_faults: int = 0;
    has aborted: bool = False;
}

obj ConeStat {
    has cone: int;
    has pieces: int;
    has losses: int;
    has yield_pct: int;
}

def log_firing(batch: str, cone: int, pieces: int, cracked: int, glaze_faults: int) -> Firing {
    return root ++> Firing(batch=batch, cone=cone, pieces=pieces, cracked=cracked, glaze_faults=glaze_faults);
}
