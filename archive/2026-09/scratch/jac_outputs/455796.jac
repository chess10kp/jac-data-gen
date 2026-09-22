"""Find bands within a target average range with enough shows."""
def find_bands(
    bands: dict[str, list[float]],
    target_avg: tuple[float, int],
    target_range: float,
    min_shows: int
) -> list[str] {
    lower_bound = target_avg[0] - target_range;
    upper_bound = target_avg[0] + target_range;
    noted_scores = target_avg[1];
    result = [];
    for (name, scores) in bands.items() {
        if len(scores) >= min_shows {
            avg = sum(scores) / len(scores) if len(scores) <= noted_scores
                else sum(scores[0:noted_scores]) / noted_scores;
            if avg >= lower_bound and avg <= upper_bound {
                result.append(name);
            }
        }
    }
    return result;
}