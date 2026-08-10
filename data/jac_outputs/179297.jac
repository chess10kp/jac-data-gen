"""Prepends each line in `string` with `prefix`."""
def string_prepend(prefix: str, string: str) -> str {
    sub = "\n" + prefix;
    return prefix + string.replace("\n", sub);
}