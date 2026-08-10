def _list(values: list | dict | int | float | str | bool) -> list {
    if isinstance(values, list) {
        return sum([_list(df) for df in values], []);
    } elif isinstance(values, dict) {
        return _list(list(values.values()));
    } else {
        return [values];
    }
}