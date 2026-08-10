"""
Compare two iterable objects
compares each element in 'a' with every element in 'b'
(Elements in 'a' are prioritized)
Returns None if there is no match
"""
def first(a: list[str], b: list[str]) -> list[str] | None {
    for elem in a {
        if elem in b {
            return a;
        }
    }
    return None;
}