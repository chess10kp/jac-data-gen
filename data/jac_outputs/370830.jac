"""Return AP (Average Precision) with target and results."""
def AP(target: list[object], results: list[list[object]]) -> float {
    n = 1;
    hit = 0;
    ap = 0.0;
    len_target = len(target);
    for res in results {
        (small_set, big_set) = (target, res) if len_target < len(res) else (res, target);
        for item in small_set {
            if item in big_set {
                hit += 1;
                ap += hit / n;
                break;
            }
        }
        n += 1;
    }
    return ap / hit;
}