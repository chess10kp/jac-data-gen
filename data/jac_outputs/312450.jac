"""Remove spaces."""
def cleanfield(value: str | None) -> str | None {
    if value is None or value.strip() == "" {
        return None;
    }
    value = str(value);
    value = value.strip();
    return value;
}