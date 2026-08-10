class Scored(Protocol) {
    score: float;
}

"""Calculate average scores for each director"""
def calculate_avg_movie_score(movies: list[Scored]) -> float {
    ratings = [m.score for m in movies];
    return round(sum(ratings) / max(1, len(ratings)), 1);
}