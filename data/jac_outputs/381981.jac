"""Returns true if the given row has at least one translation."""
def _has_at_least_one_translation(row: dict[str, object], prefix: str, langs: list[str]) -> bool {
    return any(row.get(prefix + '_' + l) for l in langs);
}