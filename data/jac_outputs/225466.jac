"""Converts a spaced string in a list of integer."""
def str_space_to_int_list(string: str) -> list[int] {
    string_list = string.split(" ");
    if string_list != '' {
        return [int(element) for element in string_list if element != ''];
    }
    return [];
}