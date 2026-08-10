"""Convert a list of lists into a list of tuples."""
def get_list_of_tuples(list_given: list[list]) -> list[tuple] {
    return [tuple(list_item) for list_item in list_given];
}