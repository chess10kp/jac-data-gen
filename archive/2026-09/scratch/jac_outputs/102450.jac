"""Strip white space from a string or list of strings."""
def strip_entry_value(entry_value: str | list[str]) -> str | None {
    if isinstance(entry_value, list) {
        return ' '.join([value.strip() for value in entry_value]);
    }
    if isinstance(entry_value, str) {
        return entry_value.strip();
    }
}