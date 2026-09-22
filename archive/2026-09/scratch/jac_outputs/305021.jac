"""Return True if exactly one member of iter is truthy, else False."""
def one(iter: set[bool | str | None]) -> bool {
    return len([s for s in iter if s]) == 1;
}