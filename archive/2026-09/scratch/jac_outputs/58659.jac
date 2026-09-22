"""Check whether a given expansion is shorter than the acronym."""
def _is_short_form(acro: str, full: str) -> bool {
    return len(full.split()) < len(acro);
}