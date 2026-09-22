"""
    Aggregate the given scores by choosing the highest one
    """
def aggregate_scores_max(scores: list) -> object {
    if not scores {
        return "N/A";
    }
    end_score = -1;
    for score in scores {
        try {
            score = float(score);
        } except ValueError {
            continue;
        }
        if (score > end_score) {
            end_score = score;
        }
    }
    end_score = max(0, end_score);
    end_score = min(10, end_score);
    return end_score;
}