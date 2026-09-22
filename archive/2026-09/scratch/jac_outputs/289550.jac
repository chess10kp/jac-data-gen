"""Remove empty entries in a nested list/dictionary of items, deep removing nested empty entries."""
def clean_empty(data: dict | list | str | int | float | bool | None) -> dict | list | str | int | float | bool | None {
    if isinstance(data, dict) {
        cleaned = {k: clean_empty(v) for (k, v) in data.items()};
        return {k: v for (k, v) in cleaned.items() if v};
    }
    if isinstance(data, list) {
        return [v for v in map(clean_empty, data) if v];
    }
    return data;
}