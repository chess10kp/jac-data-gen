"""Divide a list by two and return two lists."""
def split_list(items: list[int | str]) -> tuple[list[int | str], list[int | str]] {
    half = len(items) // 2;
    return (items[:half], items[half:]);
}