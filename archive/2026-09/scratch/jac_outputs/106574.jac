"""Returns the intersection of 'badargs' and the non-Null keys of 'dictionary'."""
def _get_any_bad_args(badargs: list[str], dictionary: dict[str, str | int | float | bool | None]) -> list[str] {
    return [
        illegal
        for illegal in badargs
        if illegal in dictionary and dictionary[illegal] is not None
    ];
}