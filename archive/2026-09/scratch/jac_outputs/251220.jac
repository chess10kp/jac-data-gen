"""
	For reducing the duplicate lines in the 'get_single_training_movie' function.
	"""
def build_training_response(
    mongodb_result: dict[str, str | int | float | list[str]],
    hug_timer: int | float,
    remaining_count: int
) -> dict[str, str | int | float | bool | list[str]] {
    return {
        'imdbID': mongodb_result['imdbID'],
        'plot': mongodb_result['plot'],
        'year': mongodb_result['year'],
        'poster_url': mongodb_result['poster'],
        'actors': mongodb_result['actors'],
        'director': mongodb_result['director'],
        'genres': mongodb_result['genre'],
        'title': mongodb_result['title'],
        'imdbRating': mongodb_result['imdbRating'],
        'remaining': remaining_count,
        'success': True,
        'valid_key': True,
        'took': float(hug_timer)
    };
}