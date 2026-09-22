"""A separator for an entirely comma-separated list given current item
    index `i` and total list length `length`. `None` if there should be
    no separator (last item).
    """
def _comma_separator(i: Any, length: Any) -> object {
    if (length == 1) {
        return None;
    } elif (i != (length - 1)) {
        return ", ";
    } else {
        return None;
    }
}