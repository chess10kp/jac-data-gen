"""Takes a list of lists and returns their transpose."""
def transpose_tabular(rows: list[list[object]]) -> list[list[object]] {
    return list(map(list, zip(*rows)));
}