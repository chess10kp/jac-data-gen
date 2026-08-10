"""Efficently calculates the number of nodes at given merkle tree height"""
def calc_tree_width(height: int, txcount: int) -> int {
    return (txcount + (1 << height) - 1) >> height;
}