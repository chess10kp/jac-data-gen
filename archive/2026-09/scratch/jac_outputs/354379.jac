"""Private function to check whether all elements of list_to_check are equal."""
def _all_elements_equal(list_to_check: list[str]) -> bool {
    if len(list_to_check) == 1 {
        return True;
    }
    return all(list_to_check[i] == list_to_check[i + 1] for i in range(len(list_to_check) - 1));
}