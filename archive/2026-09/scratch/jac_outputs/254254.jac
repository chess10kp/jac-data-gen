"""Like _index_list_of_values, but uses get to access and
returns an empty list if the key is absent.
Returns d[k] or [d[k]] if the value is not a list"""
def _get_index_list_of_values(
    d: dict[str | int, list[int | str] | int | str | None],
    k: str | int,
    def_value: list[int | str] | int | str | None = None
) -> list[int | str] {
    v = d.get(k, def_value);
    if v is None {
        return [];
    }
    if isinstance(v, list) {
        return v;
    }
    return [v];
}