"""Implement an algorithm to determine if a string has all unique characters."""
def unique2(s: str) -> bool {
    return len(set(s)) == len(s);
}