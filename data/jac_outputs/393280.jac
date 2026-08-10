import from re { Match }

"""Takes in a list of Match objects and returns the minimal start point among
    them. If there aren't any successful matches it returns the length of
    the searched string."""
def __firstMatch(matches: list[Match[str] | None], string: str) -> int {
    starts = map(
        lambda (m: Match[str] | None) { len(string) if m is None else m.start(); },
        matches
    );
    return min(starts);
}