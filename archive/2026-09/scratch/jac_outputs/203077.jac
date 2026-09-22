"""
Utility function will pick either the custom overriden value or the default
value for the row.
"""
def get_processed_row(data: dict[str, str | int | float | bool | None], key: str) -> str | int | float | bool | None {
    override_key = key + '_r';
    if data[override_key] {
        return data[override_key];
    }
    return data[key];
}