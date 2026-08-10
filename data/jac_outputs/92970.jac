"""Takes a list containing floats and creates a string of its entries such that each float value is separated by a space. Such a string is often used in urdfs - helper function for urdf creation."""
def spaced_str(input_list: list[float]) -> str {
    assert isinstance(input_list, list), "input_list has to be a list";
    return ' '.join([str(elem) for elem in input_list]);
}