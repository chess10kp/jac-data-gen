"""
Function that computes the jaccard score between two sequences

Input: two tuples; (start index of answer, length of answer). Guaranteed to overlap
Output: jaccard score computed for the two sequences
"""
def get_jaccard_score(a: tuple[int, int], s: tuple[int, int]) -> float {
    a_start = a[0];
    a_end = a[0] + a[1] - 1;
    start = s[0];
    end = s[0] + s[1] - 1;
    pred_ids = set(range(start, end + 1));
    label_ids = set(range(a_start, a_end + 1));
    len(pred_ids.intersection(label_ids)) / len(pred_ids.union(label_ids))
}