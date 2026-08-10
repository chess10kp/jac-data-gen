"""Remove elements from object_state_arr."""
def remove_arr_elements[T](arr_element: list[T], count: int) -> list[T] {
    for _ in range(count) {
        arr_element.pop();
    }
    return arr_element;
}