""" Obtained from: https://github.com/doukremt/distance/blob/master/distance/_simpledists.py
        on Sept 8 2015

    Compute the Jaccard distance between the two sequences `seq1` and `seq2`.
    They should contain hashable items.
    The return value is a float between 0 and 1, where 0 means equal, and 1 totally different.
    """
def jaccard(seq1: list[str | int], seq2: list[str | int]) -> float {
    (set1, set2) = (set(seq1), set(seq2));
    return 1 - len(set1 & set2) / float(len(set1 | set2));
}