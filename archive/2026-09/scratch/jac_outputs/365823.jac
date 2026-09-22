"""
    Used to get the top results to display for keyword filtering

    Given a dictionary of keywords as keys and the number of times that keyword is linked to a statement in the search results: {Iraq : 300}
    Returns the top n results as as list of pairs, ordered by appearances: [(Iraq, 300), (Iran, 200)]
    """
def get_top_keywords(keywords_dict: Any, top_n: Any) -> object {
    return sorted(
        keywords_dict.items(), key=lambda (student: Any) { student[1]; }, reverse=True
    )[:top_n];
}