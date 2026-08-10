"""Return True if all args are None."""
def all_are_none(*args: object) -> bool {
    return all(arg is None for arg in args);
}