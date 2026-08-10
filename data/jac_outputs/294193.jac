"""Reverse a dict, so each value in it maps to one of its keys."""
def reverse_dict_partial(dict_obj: dict[str, int]) -> dict[int, str] {
    return {dict_obj[key]: key for key in dict_obj};
}