"""Count the number of items in seq.

Like the builtin ``len`` but works on lazy sequencies.
"""
def count(seq: list | tuple | str) -> int {
    if hasattr(seq, '__len__') {
        return len(seq);
    }
    return sum(1 for i in seq);
}