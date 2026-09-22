"""Counts the "for" and "against" ballots"""
def count_ballots(ballots: dict[str, dict[str, list[str]]]) -> tuple[dict[str, int], dict[str, int], tuple[str, ...]] {
    results_for = {};
    results_against = {};
    blanks = [];
    for (name, ballot) in ballots.items() {
        if not ballot['for'] and not ballot['against'] {
            blanks.append(name);
            continue;
        }
        for candidate in ballot['for'] {
            results_for[candidate] = results_for.get(candidate, 0) + 1;
        }
        for candidate in ballot['against'] {
            results_against[candidate] = results_against.get(candidate, 0) - 1;
        }
    }
    return (results_for, results_against, tuple(sorted(blanks)));
}