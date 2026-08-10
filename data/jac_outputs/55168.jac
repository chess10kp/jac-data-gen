"""Given a list of integers and optionally a start and an end
finds all integers from start to end that are not in the list."""
def find_missing(integers_list: list[int], start: int | None = None, limit: int | None = None) -> list[int] {
    start = start if start is not None else integers_list[0];
    limit = limit if limit is not None else integers_list[-1];
    return [i for i in range(start, limit + 1) if i not in integers_list];
}