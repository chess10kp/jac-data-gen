"""Determine if indicated string is exactly contained in the calling string."""
def _string_contains(arg: str, substr: str) -> bool {
    return arg.find(substr) >= 0;
}