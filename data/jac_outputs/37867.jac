"""Helper function to reorder a list of coordinates from [W,S,E,N] to [W,E,S,N]

    args:
        bbox (list[float]): list (or tuple) or coordinates in the order of [W,S,E,N]

    returns:
        extent (tuple[float]): tuple of coordinates in the order of [W,E,S,N]
    """
def bbox_to_extent(bbox: Any) -> object {
    return (bbox[0], bbox[2], bbox[1], bbox[3]);
}