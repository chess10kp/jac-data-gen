"""
    Generates a frequency count of each rating on the scale
    ratings is a list of scores
    Returns a list of frequencies
    """
def histogram(ratings: list[float], min_rating: int | None = None, max_rating: int | None = None) -> list[int] {
    ratings = [int(r) for r in ratings];
    min_val = min_rating if min_rating is not None else min(ratings);
    max_val = max_rating if max_rating is not None else max(ratings);
    num_ratings = int(max_val - min_val + 1);
    hist_ratings = [0 for _ in range(num_ratings)];
    for r in ratings {
        hist_ratings[r - min_val] += 1;
    }
    return hist_ratings;
}