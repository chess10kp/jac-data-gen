"""
    both type dict
    """
def merge_lines_scores(lines: dict[str, tuple[list, list]], scores: dict[str, list]) -> dict[str, list] {
    ret = {};
    for (k, v) in lines.items() {
        score_data = scores.get(k);
        if not score_data {
            score_data = [None for _ in range(5)];
        }
        row = v[0] + score_data + v[1];
        ret[k] = row;
    }
    return ret;
}