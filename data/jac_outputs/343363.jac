"""Normalize score to 0.5 center, scale by 2 std devs, clip to [0, 1]."""
def normalize_score(score: float, mean: float, std: float) -> float {
    score -= mean;
    if std != 0 {
        score /= std * 2;
    }
    score += 0.5;
    if score < 0 {
        score = 0;
    } elif score > 1 {
        score = 1;
    }
    return score;
}