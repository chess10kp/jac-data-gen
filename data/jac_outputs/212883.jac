"""Rescale positive scores to [0.5, 1.0] and negative scores to [0.0, 0.5]."""
def rescale_score_by_abs(score: float, max_score: float, min_score: float) -> float | None {
    if max_score > 0 and min_score < 0 {
        if max_score >= -min_score {
            if score >= 0 {
                return 0.5 + 0.5 * (score / max_score);
            }
            return 0.5 - 0.5 * ((-score) / max_score);
        }
        if score >= 0 {
            return 0.5 + 0.5 * (score / (-min_score));
        }
        return 0.5 - 0.5 * (score / min_score);
    } elif max_score > 0 and min_score >= 0 {
        if max_score == min_score {
            return 1.0;
        }
        return 0.5 + 0.5 * (score / max_score);
    } elif max_score <= 0 and min_score < 0 {
        if max_score == min_score {
            return 0.0;
        }
        return 0.5 - 0.5 * (score / min_score);
    }
}