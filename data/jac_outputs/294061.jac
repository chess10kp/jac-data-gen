"""
Replace special string
"""
def _replace_special_string(string: str | int | float | bool, old_list: list[str], new_list: list[str]) -> str {
    for (old, new) in zip(old_list, new_list) {
        string = string.__str__().replace(old, new);
    }
    return string as str;
}