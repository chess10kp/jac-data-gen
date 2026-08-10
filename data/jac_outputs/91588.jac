"""Return whether any dictionary word starts with the given prefix."""
def has_prefix(sub_s: str, current_dict: list[str]) -> bool {
    return any(w.startswith(sub_s) for w in current_dict);
}