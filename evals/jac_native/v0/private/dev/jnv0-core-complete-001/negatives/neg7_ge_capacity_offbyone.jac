# MUTANT kills: "exact capacity accepted" (R1) — off-by-one rejects exact fit
obj Request {
    has id: str;
    has count: int;
}

obj AllocationResult {
    has accepted: list[str];
    has rejected: list[str];
    has used: int;
}

def allocate_requests(requests: list[Request], capacity: int) -> AllocationResult {
    accepted: list[str] = []; rejected: list[str] = []; seen: set[str] = set(); used: int = 0;
    for r in requests {
        if r.id in seen or r.count <= 0 or used + r.count >= capacity {
            rejected.append(r.id);
        } else {
            seen.add(r.id); accepted.append(r.id); used += r.count;
        }
    }
    return AllocationResult(accepted=accepted, rejected=rejected, used=used);
}
