"""Get labels to add that were already known in the pull request."""
def get_new_in_current(l_new: list[str], l_old: list[str], pattern_dict: dict[str, str]) -> list[str] {
    return [l for l in l_new if l in l_old and l in pattern_dict];
}