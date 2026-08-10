"""Returns a string showing indices for a cell in simulator protocol, from data in simulator protocol."""
def string_ijk1_for_cell_ijk1(cell_ijk1: tuple[int, int, int]) -> str {
    return '[{:}, {:}, {:}]'.format(cell_ijk1[0], cell_ijk1[1], cell_ijk1[2]);
}