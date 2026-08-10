"""Return the last n items of given sequence.

    This works for non-lists but it doesn't when the given n is 0. This is
    because sequence[-0:] is the same thing as sequence[0:] and that will
    return the entire sequence (which is likely not 0 items)
    """
def v1_tail(sequence: list[int] | str, n: int) -> list[int | str] {
    list(sequence[-n:])
}