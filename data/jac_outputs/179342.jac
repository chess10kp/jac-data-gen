"""
        Sorts a dictionary in ascending order (if descending = False) or descending order (if descending = True)
    """
def sort_dict(unsorted_dict: Any, descending: Any = False) -> object {
    if not isinstance(descending, bool) {
        raise ValueError('`descending` must be a boolean');
    }
    return sorted(
        unsorted_dict.items(), key=lambda (x: Any) { x[1]; }, reverse=descending
    );
}