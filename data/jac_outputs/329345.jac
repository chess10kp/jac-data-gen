"""Quote a value if it isn't quoted yet."""
def format_value(value: str | int | float | bool, tag: bool = False) -> str {
    if tag {
        if not isinstance(value, str) {
            value = str(value);
        }
        return value.replace(' ', '-');
    }
    if isinstance(value, str) {
        if value.startswith('"') and value.endswith('"') {
            return value;
        }
    }
    return '"{}"'.format(value);
}