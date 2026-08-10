"""Will recursively flatten a nested list"""
def flatten_list(list_of_lists: list[object]) -> list[object] {
    if len(list_of_lists) == 0 {
        return list_of_lists;
    }
    if isinstance(list_of_lists[0], list) {
        return flatten_list(list_of_lists[0]) + flatten_list(list_of_lists[1:]);
    }
    return list_of_lists[:1] + flatten_list(list_of_lists[1:]);
}