"""Return True iff val is "1", "yes", or "true", otherwise False."""
def _bool(val: str) -> bool {
    return val.lower() in ('1', 'yes', 'true');
}