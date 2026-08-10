"""check if data exists. compares dict to empty dict else to None"""
def has_data(data: dict[str, str] | str | int | float | bool | None) -> bool {
    if isinstance(data, dict) {
        return data != {};
    }
    return data is not None;
}