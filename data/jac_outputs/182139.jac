"""
    target_width: integer
        width for feature in face. For example width of  bounding box for eyes.
    filter_width: integer
        width of filter
    """
def get_best_scaling(target_width: Any, filter_width: Any) -> object {
    return (1.1 * (target_width / filter_width));
}