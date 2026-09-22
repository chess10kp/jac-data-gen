"""Add two arrays or graphs; return the second if the first is None."""
def add_two(one: list[int] | None, two: list[int], **kwargs: dict[str, str]) -> list[int] {
    if one is None {
        return two;
    }
    return one + two;
}