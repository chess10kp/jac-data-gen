# MUTANT kills: "input list and objects are not mutated" (R8)
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
    while len(requests) > 0 {
        r = requests.pop(0);
        if r.id in seen or r.count <= 0 or used + r.count > capacity {
            rejected.append(r.id);
        } else {
            seen.add(r.id); accepted.append(r.id); used += r.count;
        }
    }
    return AllocationResult(accepted=accepted, rejected=rejected, used=used);
}
