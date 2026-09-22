"""Returns first occurrence of any of items in seq, or None."""
def first_in_set(seq: list[str], items: set[str]) -> str | None {
    for s in seq {
        if s in items {
            return s;
        }
    }
}