"""Returns the value at the end of the list of keys."""
def valueForKeyList(d: dict[str, int | dict[str, int | dict[str, int | dict[str, int]]]], keys: tuple[str, ...], `default: int | str | dict[str, int | dict[str, int | dict[str, int]]] | None = None) -> int | dict[str, int | dict[str, int | dict[str, int | dict[str, int]]]] | str | None {
    var: dict[str, int | dict[str, int | dict[str, int | dict[str, int]]]] | int = d;
    for key in keys {
        if not key in var {
            return `default;
        }
        var = var[key];
    }
    return var;
}