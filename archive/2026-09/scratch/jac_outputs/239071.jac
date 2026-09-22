"""Converts given string to a valid Maya string."""
def get_compatible_name(name_str: str) -> str {
    return ''.join([c if c.isalnum() else '_' for c in name_str]);
}