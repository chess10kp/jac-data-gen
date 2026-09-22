"""Sorts a list of SimilarPatterns, leaving the highest score first."""
def _SortSimilarPatterns(similar_patterns: Any) -> object {
    return sorted(similar_patterns, key=lambda (x: Any) { x.score; }, reverse=True);
}