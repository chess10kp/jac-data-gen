"""compares the number of '(' and ')' and makes sure they're equal.
    Return bool True is ok and False is not a valid structure."""
def equal_para(struct: str) -> bool {
    return struct.count('(') == struct.count(')');
}