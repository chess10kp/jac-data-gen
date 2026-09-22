"""
listify a query result consisting of user types

returns nested arrays representing user type ordering
"""
def listify(item: list[str | int] | tuple[str | int, ...] | str | int) -> list[str | int] | str | int {
    if isinstance(item, (tuple, list)) {
        return [listify(i) for i in item] as list[str | int];
    }
    return item;
}