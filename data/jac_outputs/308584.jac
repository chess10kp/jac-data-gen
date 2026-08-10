"""Test if a string looks like a boolean value."""
def str2bool(text: str | int | float | bool, `test: bool = True) -> bool {
    if `test {
        return str(text).lower() in ['1', 'y', 'yes', 't', 'true', 'ok', 'on'];
    } else {
        return str(text).lower() in ['0', 'n', 'no', 'none', 'f', 'false', 'off'];
    }
}