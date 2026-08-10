"""Max number of nodes in the lowest layer of a tree of given height."""
def layer(height: int) -> int {
    assert height > 0;
    return 2 ** (height - 1);
}