"""make sure x is a list"""
def mlist(x: str | int | list[str | int]) -> list[str | int] {
    if isinstance(x, list) {
        return x;
    }
    return [x];
}