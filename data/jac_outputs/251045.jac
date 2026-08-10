"""comparator for sorting by sentiment"""
def score_sort_cmp(es_hit: dict[str, dict[str, float]]) -> float {
    return es_hit['vader_score']['compound'];
}