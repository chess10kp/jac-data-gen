"""Returns a new sequence containing all but the last element of the input sequence.
    If the input sequence is empty, a new empty sequence of the same type should be returned.
    """
def all_but_last(seq: str) -> str {
    result = seq * 0;
    for i in range(len(seq) - 1) {
        result += seq[i];
    }
    return result;
}