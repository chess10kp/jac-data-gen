"""Returns true if any of the arguments are None."""
def test_none(*args: object) -> bool {
    return any(x is None for x in args);
}