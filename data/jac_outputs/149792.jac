"""Takes a string or a list and converts strings to one item lists"""
def listify(string_or_list: str | list[object]) -> list[object] {
    if hasattr(string_or_list, 'startswith') {
        return [string_or_list];
    }
    return string_or_list;
}