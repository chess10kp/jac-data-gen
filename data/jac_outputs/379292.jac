"""Return string splitted at the desired separator."""
def split_at(string: str, sep: str, pos: int) -> list[str] {
    parts = string.split(sep);
    return [sep.join(parts[:pos]), sep.join(parts[pos:])];
}