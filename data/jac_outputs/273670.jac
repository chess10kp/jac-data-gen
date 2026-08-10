"""When terminals dont support the extended set of markup values."""
def _standardize_markups(markups: int | list[int]) -> list[int] {
    if not markups {
        return [];
    }
    if not isinstance(markups, list) {
        markups = [markups];
    }
    return [markup - 60 if markup > 90 else markup for markup in markups];
}