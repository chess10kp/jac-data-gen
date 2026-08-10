"""
    Expand the bounding box by a given amount in the vertical direction.

    Keyword arguments:
    bbox -- the bounding box to expand
    increase -- the amount to expand the bounding box

    Returns: the expanded bounding box
    """
def _vertically_expand_bounding_box(bbox: tuple[int, int, int, int], increase: int) -> tuple[int, int, int, int] {
    return (bbox[0], bbox[1], bbox[2], bbox[3] + increase);
}