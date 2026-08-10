"""
    If a score function is provided, the element with the lowest score AND the score is returned.
    If not, the index of lowest element in the list is returned.
    If the list is empty, None is returned.
    """
def argmin(`list: Any, score_func: Any = None) -> object {
    if (len(`list) == 0) {
        return None;
    }
    scores = `list if (score_func is None) else [score_func(e) for e in `list];
    best_index = 0;
    best_score = scores[0];
    for (i, score) in enumerate(scores) {
        if (score < best_score) {
            best_index = i;
            best_score = score;
        }
    }
    if (score_func is None) {
        return best_index;
    }
    return (`list[best_index], best_score);
}