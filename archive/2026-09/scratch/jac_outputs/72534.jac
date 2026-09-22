"""
Takes in a json "row" and filters the keys to match the starts_with
parameter. In addition, it will remove any match that is included
in the does_not_match parameter.
"""
def columns_matching_pattern(
    row: dict[str, object],
    starts_with: str,
    does_not_match: list[str] = []
) -> dict[str, object] {
    candidates = {
        k: v
        for (k, v) in row.items()
        if str(k).startswith(starts_with)
    };
    for bad_key in does_not_match {
        if bad_key in candidates {
            candidates.pop(bad_key);
        }
    }
    return {k[len(starts_with):].strip(): v for (k, v) in candidates.items()};
}