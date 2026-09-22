"""Given a dictionary, returns new dictionary that maps release year to a
list of IMBD ratings for each of those years."""
def year_to_rating(movie_map: dict[str, dict[str, int | float]]) -> dict[int | float, list[int | float]] {
    year_to_rating_map: dict[int | float, list[int | float]] = {};
    for movie in movie_map {
        year = movie_map[movie]['release_year'];
        rating = movie_map[movie]['imbd_rating'];
        if year not in year_to_rating_map {
            year_to_rating_map[year] = [];
        }
        year_to_rating_map[year].append(rating);
    }
    return year_to_rating_map;
}