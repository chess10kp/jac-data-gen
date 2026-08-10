"""
    Returns list ang cycled such that the ang[2] is the smallest angle
    """
def SPAlt(ang: list[int]) -> list[int] {
    index_min = 0;
    item_min = 360;
    for (i, item) in enumerate(ang) {
        if item < item_min {
            index_min = i;
            item_min = item;
        }
    }
    return ang[((index_min - 2) % 4):] + ang[:((index_min - 2) % 4)];
}