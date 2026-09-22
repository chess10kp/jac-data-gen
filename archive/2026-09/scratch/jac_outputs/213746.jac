"""Get ".ext" (extension) of string "_str"."""
def get_extension(_str: str) -> str {
    _str = str(_str).rsplit("/", 1)[-1];
    ext = "." + _str.rsplit(".", 1)[-1];
    return ext;
}