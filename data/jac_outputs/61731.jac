"""
    Ars: two lists of batches

    Returns True if the corresponding batches in lists are different
    Returns False otherwise
    """
def batches_shuffled(batch_list1: list[list[int]], batch_list2: list[list[int]]) -> bool {
    for (b1, b2) in zip(batch_list1, batch_list2) {
        if b1 == b2 {
            return False;
        }
    }
    return True;
}