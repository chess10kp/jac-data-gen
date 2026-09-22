"""Flatten lists of lists of any depth. Preserves tuples."""
def flatten(x: list[int | str | tuple | list]) -> list[int | str | tuple] {
    result = [];
    for el in x {
        if (
            hasattr(el, "__iter__")
            and not isinstance(el, str)
            and type(el) != tuple
            and not issubclass(type(el), tuple)
        ) {
            result.extend(flatten(el as list[int | str | tuple | list]));
        } else {
            result.append(el);
        }
    }
    return result;
}