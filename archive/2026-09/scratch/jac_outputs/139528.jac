"""Returns a simple list without sub-lists."""
def _Flatten(values: list[int | str | float | list]) -> list[int | str | float] {
    ret: list[int | str | float] = [];
    for entry in values {
        if isinstance(entry, list) {
            ret.extend(_Flatten(entry));
        } else {
            ret.append(entry);
        }
    }
    return ret;
}