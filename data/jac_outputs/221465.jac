"""Make maybe list a list if it is not."""
def listify(maybe_list: int | str | float | bool | None | list[object]) -> list[object] {
    return [maybe_list] if not isinstance(maybe_list, list) else maybe_list;
}