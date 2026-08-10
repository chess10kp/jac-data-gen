"""Returns first occurrence of any of items in seq, or None."""
def first_not_in_set(seq: list[int | str], items: set[int | str] | list[int | str]) -> int | str | None {
    for s in seq {
        if s not in items {
            return s;
        }
    }
}