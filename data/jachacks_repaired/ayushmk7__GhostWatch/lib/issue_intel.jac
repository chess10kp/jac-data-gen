# lib/issue_intel.jac — Fingerprint + TTL helpers for GitHub issue digest caching (no network).

def:pub issues_fingerprint_from_list(issues: list) -> str;

def:pub issue_digest_cache_fresh(digest_fetched_at: str, now_ts: int, ttl_seconds: int) -> bool;

def:pub issues_fetch_cache_fresh(issues_fetched_at: str, now_ts: int, ttl_seconds: int) -> bool;
