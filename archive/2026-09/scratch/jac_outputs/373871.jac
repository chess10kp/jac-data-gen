"""Creates an ordered list from a list of tuples or other hashable items."""
def unique_list(a_list: list[int | str | tuple[int, int]]) -> list[int | str | tuple[int, int]] {
    seen: dict[int | str | tuple[int, int], int] = {};
    result: list[int | str | tuple[int, int]] = [];
    for item in a_list {
        if item not in seen {
            seen[item] = 1;
            result.append(item);
        }
    }
    return result;
}