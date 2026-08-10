"""Return the first element or None from an lxml selector result."""
def first_element_or_none(element_list: list[object]) -> object | None {
    if element_list {
        return element_list[0];
    }
    return;
}