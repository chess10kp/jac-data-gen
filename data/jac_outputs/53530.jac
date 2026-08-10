"""Converts a string to a boolean value."""
def str2bool(value: str | bool) -> str | bool {
    if `type(value) == bool {
        return value as bool;
    }
    return (value as str) and (value as str).lower() in ('yes', 'true', 't', '1', 'y');
}