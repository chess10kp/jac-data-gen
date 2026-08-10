"""Check whether a list of items appear in a given list of options.

    Returns a list of 1 and 0, one for each candidate given."""
def belong(candidates: list[int], checklist: list[int]) -> list[bool] {
    return [x in checklist for x in candidates];
}