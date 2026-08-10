"""Check if any of the strings in `list_of_strings` is  a substrings of `string`"""
def list_of_strings_has_substring(list_of_strings: list[str], string: str) -> bool {
    return any(elem.lower() in string.lower() for elem in list_of_strings);
}