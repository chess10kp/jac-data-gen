"""Convert v to a tuple if it is a list."""
def _list_to_tuple(v: list[object] | str | int | float | bool | tuple[object, ...] | dict[str, object] | None) -> tuple[object, ...] | str | int | float | bool | tuple[object, ...] | dict[str, object] | None {
    if isinstance(v, list) {
        return tuple(v);
    }
    return v;
}