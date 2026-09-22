"""Computes the jaccard coefficient between two sets."""
def jaccard(set1: set[object], set2: set[object]) -> int | float {
    if len(set1) == 0 or len(set2) == 0 {
        return 0;
    }
    inter = len(set1.intersection(set2));
    return inter / (len(set1) + len(set2) - inter);
}