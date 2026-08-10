"""Takes special_results, a list of dicts; returns election years rounded up to even."""
def format_special_results(special_results: list[dict[str, int]] = []) -> list[int | None] {
    senate_specials: list[int | None] = [];
    for result in special_results {
        result["election_year"] = result["election_year"] + result["election_year"] % 2;
        senate_specials.append(result.get("election_year", None));
    }
    return senate_specials;
}