"""Evaluates if a is sorted or not."""
def is_sorted(a: list[int | str | float]) -> bool {
    return sorted(a) == a;
}