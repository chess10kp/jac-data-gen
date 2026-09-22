"""Strip trailing spaces for field name #456."""
def strip_trailing_fields_json(items: list[dict[str, str]]) -> list[dict[str, str]] {
    return [{field.strip(): item[field] for field in item} for item in items];
}