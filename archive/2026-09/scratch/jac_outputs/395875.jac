"""List utility; splits a /list/ robustly into first & rest."""
def FirstRest(tokens: list[object]) -> tuple[object | None, list[object]] {
    assert isinstance(tokens, list);
    if not tokens {
        first = None;
        rest = [];
    } else {
        first = tokens[0];
        rest = tokens[1:];
    }
    return (first, rest);
}