"""Return a list with element added between each item.

    Similar to str.join() except returns a list.

        >>>joined_list(['a', 'b', 'c'], '@')
        ['a', '@', 'b', '@', 'c']

    Args:
        items: list
        element: anything that can be an element of a list,
    """
def joined_list(items: Any, element: Any) -> object {
    work_items = `list(items);
    for x in sorted(`list(range(0, (len(work_items) - 1))), reverse=True) {
        work_items[(x + 1):(x + 1)] = element;
    }
    return work_items;
}