"""Smooth the [bgn, fin] pairs.
    """
def smooth(bgn_fin_pairs: list[list[int]], n_smooth: int) -> list[list[int]] {
    new_bgn_fin_pairs = [];
    if len(bgn_fin_pairs) == 0 {
        return [];
    }
    [mem_bgn, fin] = bgn_fin_pairs[0];
    for n in range(1, len(bgn_fin_pairs)) {
        [pre_bgn, pre_fin] = bgn_fin_pairs[n - 1];
        [bgn, fin] = bgn_fin_pairs[n];
        if bgn - pre_fin <= n_smooth {
        } else {
            new_bgn_fin_pairs.append([mem_bgn, pre_fin]);
            mem_bgn = bgn;
        }
    }
    new_bgn_fin_pairs.append([mem_bgn, fin]);
    return new_bgn_fin_pairs;
}