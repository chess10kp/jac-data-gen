"""Check whether a rate limit is None or unlimited (indicated by '-1')."""
def is_unlimited(rate_limit: int | None) -> bool {
    return rate_limit is None or rate_limit == -1;
}