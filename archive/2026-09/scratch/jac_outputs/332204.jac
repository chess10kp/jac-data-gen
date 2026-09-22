"""Return a splglob that either matches a full path or match a simple file."""
def splglob_simple(pattern: str) -> str {
    if "/" not in pattern {
        pattern = "^.../{}$".format(pattern);
    } else {
        pattern = "^{}$".format(pattern);
    }
    return pattern;
}