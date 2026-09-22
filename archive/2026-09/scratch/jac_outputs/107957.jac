"""Checks if a list is entirely composed of dictionaries

    l ([]): List of any type

    returns (bool): True if l is entirely composed of dicts
"""
def is_list_of_dict(l: list[int | str | float | bool | dict[str, str]]) -> bool {
    return all(`type(x) == dict for x in l);
}