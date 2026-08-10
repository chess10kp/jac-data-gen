"""Returns the first element in seq with the given name."""
def find_by_name(seq: Any, name: Any) -> object {
    for item in seq {
        if (item['name'] == name) {
            return item;
        }
    }
    return None;
}