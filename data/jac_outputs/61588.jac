"""Recursively steps down the children of an event to calculate the number
    of children.

    Args:
      event (json): Json representing the current event.

    Returns:
      The number of children of the current event.
"""
def _count_number_of_children_recursively(event: Any) -> object {
    if (len(event['children']) == 0) {
        return 0;
    }
    children = 0;
    for child in event['children'] {
        children += 1 + _count_number_of_children_recursively(child);
    }
    return children;
}