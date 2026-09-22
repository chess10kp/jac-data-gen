"""Return whether any word in the dictionary has the given prefix."""
def has_prefix(sub_s: str | None, dic: list[str]) -> bool {
    if sub_s is None {
        return True;
    }
    for word in dic {
        if word.startswith(sub_s) {
            return True;
        }
    }
    return False;
}