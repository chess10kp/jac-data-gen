"""Transpose list of lists."""
def transpose_list(org_list: list[list]) -> list[list] {
    return [list(row) for row in zip(*org_list)];
}