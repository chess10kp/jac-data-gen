"""Removes thousand separator from a number stored as string."""
def remove_thousand_separator(int_as_str: str) -> str {
    return int_as_str.replace(",", "");
}