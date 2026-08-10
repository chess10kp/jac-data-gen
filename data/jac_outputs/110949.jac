"""Parse comma-separated string into list."""
def comma_separated_strings(value: str) -> list[str] {
    return [str(k).strip() for k in value.split(",")];
}