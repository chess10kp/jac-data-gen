"""Return empty string with default value "na"."""
def is_empty(in_str: str | int | float | bool | None) -> str {
    if len(str(in_str)) > 0 {
        return str(in_str);
    }
    return "na";
}