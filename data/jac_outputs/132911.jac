"""
    returns the high or medium degree node with a given label index
    labels contains the output of the label function:
    the sorted list of high degree nodes with their labels, and
    the sorted list of medium degree nodes with their labels
    note that label indices are 0-indexed too
    """
def label_index2node(
    label_index: int,
    labels: tuple[list[tuple[int, int]], list[tuple[int, int]]]
) -> int {
    (hi_pairs, med_pairs) = labels;
    if label_index < len(hi_pairs) {
        return hi_pairs[label_index][0];
    }
    error_msg = "there is no node with label " + str(label_index);
    assert label_index - len(hi_pairs) < len(med_pairs), error_msg;
    return med_pairs[label_index - len(hi_pairs)][0];
}