"""Merge two dictionaries."""
def dictmerge(x: dict, y: dict) -> dict {
    z = x.copy();
    z.update(y);
    return z;
}