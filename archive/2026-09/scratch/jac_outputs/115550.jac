""" return list of candidates who need to be eliminated this round

    WARNING: doesn't deal properly with ties in support for min candidates....
    """
def find_min_cand(counts: dict[str, int]) -> str | None {
    if len(counts.keys()) == 0 {
        return None;
    }
    curmin = min(list(counts.values()));
    for k in counts.keys() {
        if counts[k] == curmin {
            return k;
        }
    }
}