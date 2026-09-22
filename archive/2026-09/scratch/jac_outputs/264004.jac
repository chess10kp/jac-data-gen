"""Returns the inverse operation of zip on list."""
def unzip(l: list[tuple]) -> list[list] {
    return list(map(list, zip(*l)));
}