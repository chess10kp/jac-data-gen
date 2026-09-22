"""Utility function to remove duplicates from a list."""
def dedupe_list(seq: list[object]) -> list[object] {
    seen = set();
    return [x for x in seq if not (x in seen or seen.add(x))];
}