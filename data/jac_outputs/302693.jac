"""Returns a string showing grid extent in simulator protocol, from data in python protocol."""
def string_ijk_for_extent_kji(extent_kji: tuple[int, int, int]) -> str {
    return '[{:}, {:}, {:}]'.format(extent_kji[2], extent_kji[1], extent_kji[0]);
}