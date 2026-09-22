"""
    Verifies that given parameter is a list of strings
    """
def is_list_of_strings(lst: object) -> bool {
    if lst and isinstance(lst, list) {
        return all(isinstance(elem, str) for elem in lst);
    } else {
        return False;
    }
}