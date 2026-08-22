# MUTANT kills: "duplicate of accepted id rejected" (R3)
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
    accepted: list[str] = []; rejected: list[str] = []; used: int = 0;
    for r in requests {
        if r.count <= 0 or used + r.count > capacity {
            rejected.append(r.id);
        } else {
            accepted.append(r.id); used += r.count;
        }
    }
    return AllocationResult(accepted=accepted, rejected=rejected, used=used);
}
