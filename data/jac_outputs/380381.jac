"""compare two lists"""
def lists_are_same[T](L1: list[T], L2: list[T]) -> bool {
    return len(L1) == len(L2) and sorted(L1) == sorted(L2);
}