"""Return whether the given status name is frozen."""
def isFrozen(status: str) -> bool {
    return status.startswith('.');
}
