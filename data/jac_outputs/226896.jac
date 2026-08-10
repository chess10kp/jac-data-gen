"""Gets the average score for models cross validated using the cross_validate function."""
def get_average_score(tscores: list[float]) -> float {
    score = 0.0;
    for i in range(len(tscores)) {
        score += tscores[i - 1];
    }
    return score / len(tscores);
}