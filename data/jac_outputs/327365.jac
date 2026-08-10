"""Case insensitive string parsing helper. Return True for true (case insensitive matching), False otherwise."""
def is_true(s: str) -> bool {
    return s.lower() == 'true';
}