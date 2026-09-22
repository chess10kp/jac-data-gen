"""Clips the thresholds for binary search based on current word counts.

    The upper threshold parameter typically has a large default value that can
    result in many iterations of unnecessary search. Thus we clip the upper and
    lower bounds of search to the maximum and the minimum wordcount values.

    Args:
      word_counts: list of (string, int) tuples
      upper_thresh: int, upper threshold for binary search
      lower_thresh: int, lower threshold for binary search

    Returns:
      upper_search: int, clipped upper threshold for binary search
      lower_search: int, clipped lower threshold for binary search
    """
def get_search_threshs(
    word_counts: list[tuple[str, int]], upper_thresh: int | None, lower_thresh: int | None
) -> tuple[int, int] {
    counts = [count for (_, count) in word_counts];
    max_count = max(counts);
    min_count = min(counts);
    if upper_thresh is None {
        upper_search = max_count;
    } else {
        upper_search = max_count if max_count < upper_thresh else upper_thresh;
    }
    if lower_thresh is None {
        lower_search = min_count;
    } else {
        lower_search = min_count if min_count > lower_thresh else lower_thresh;
    }
    return (upper_search, lower_search);
}