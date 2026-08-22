# Structurally different: guard-clause / continue style, membership via the
# accepted list itself instead of a separate set.
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
    result = AllocationResult(accepted=[], rejected=[], used=0);
    for r in requests {
        if r.count <= 0 {
            result.rejected.append(r.id);
            continue;
        }
        if r.id in result.accepted {
            result.rejected.append(r.id);
            continue;
        }
        if result.used + r.count > capacity {
            result.rejected.append(r.id);
            continue;
        }
        result.accepted.append(r.id);
        result.used += r.count;
    }
    return result;
}
