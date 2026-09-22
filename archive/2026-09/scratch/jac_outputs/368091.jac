"""Returns the (weighted) confusion matrix between rater's ratings."""
def my_confusion_matrix(
    rater_a: list[int],
    rater_b: list[int],
    sample_weight: list[int | float],
    min_rating: int | None = None,
    max_rating: int | None = None
) -> list[list[float]] {
    assert len(rater_a) == len(rater_b);
    if min_rating is None {
        min_rating = min(rater_a + rater_b);
    }
    if max_rating is None {
        max_rating = max(rater_a + rater_b);
    }
    num_ratings = int(max_rating - min_rating + 1);
    conf_mat = [[0.0 for i in range(num_ratings)] for j in range(num_ratings)];
    for (a, b, w) in zip(rater_a, rater_b, sample_weight) {
        conf_mat[a - min_rating][b - min_rating] += w;
    }
    return conf_mat;
}