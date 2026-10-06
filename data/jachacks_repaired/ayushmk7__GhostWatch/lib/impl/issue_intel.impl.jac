# lib/impl/issue_intel.impl.jac

impl issues_fingerprint_from_list(issues: list) -> str {
    parts: list[str] = [];
    for it in issues {
        if not it {
            continue;
        }
        n = str(it.get("number", ""));
        u = str(it.get("updated_at", ""));
        parts.append(n + ":" + u);
    }
    return str(len(parts)) + "|" + "|".join(parts);
}

impl issue_digest_cache_fresh(digest_fetched_at: str, now_ts: int, ttl_seconds: int) -> bool {
    try {
        t = int(str(digest_fetched_at).strip());
        return (int(now_ts) - t) < int(ttl_seconds);
    } except Exception { # jac:ignore[W2052]
        return False;
    }
}

impl issues_fetch_cache_fresh(issues_fetched_at: str, now_ts: int, ttl_seconds: int) -> bool {
    try {
        t = int(str(issues_fetched_at).strip());
        return (int(now_ts) - t) < int(ttl_seconds);
    } except Exception { # jac:ignore[W2052]
        return False;
    }
}
