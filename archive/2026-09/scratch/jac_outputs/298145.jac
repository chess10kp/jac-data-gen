"""Return the path from a leaf to the root of a binary hash tree."""
def path(index: int, height: int) -> list[tuple[int, int]] {
    layer = 0;
    path_list = [];
    while layer < height {
        path_list.append((layer, index));
        layer += 1;
        index >>= 1;
    }
    return path_list;
}