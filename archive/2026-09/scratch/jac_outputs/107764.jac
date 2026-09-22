"""the number of documents we should not have retrieved """
def get_nFalsePositive(TP: int, atrank: int) -> int {
    n_retrieved = atrank + 1;
    return n_retrieved - TP;
}