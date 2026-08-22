# Structurally different: index-based while loop, dict used as the seen-set,
# and remaining-capacity decremented instead of used-accumulated.
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
    accepted: list[str] = [];
    rejected: list[str] = [];
    seen: dict[str, bool] = {};
    remaining: int = capacity;
    i: int = 0;
    while i < len(requests) {
        r = requests[i];
        i += 1;
        fits = r.count <= remaining;
        if (r.id not in seen) and (r.count > 0) and fits {
            seen[r.id] = True;
            accepted.append(r.id);
            remaining -= r.count;
        } else {
            rejected.append(r.id);
        }
    }
    return AllocationResult(accepted=accepted, rejected=rejected, used=capacity - remaining);
}
