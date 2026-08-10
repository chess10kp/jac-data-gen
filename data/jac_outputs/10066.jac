glob CUTOFF_RANKS = [5, 10, 15, 20, 30, 100, 200, 500, 1000];

"""Computes precision at standard cutoff ranks."""
def precision_ranges(result2rank: dict[str, list[int]], total_terms: int) -> dict[int, float] {
    map_of_prec = {};
    for cutoff in CUTOFF_RANKS {
        map_of_prec[cutoff] = sum(
            1.0 for ranks in result2rank.values()
            if any(r <= cutoff for r in ranks)
        ) / total_terms;
    }
    return map_of_prec;
}