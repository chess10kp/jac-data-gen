"""Returns a flattened version of lst."""
def flatten(lst: list) -> list {
    new_list = [];
    for i in lst {
        if type(i) == list {
            new_list += flatten(i);
        } else {
            new_list.append(i);
        }
    }
    return new_list;
}