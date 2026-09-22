"""Return the words-per-minute (WPM) of the TYPED string.

    Arguments:
        typed: an entered string
        elapsed: an amount of time in seconds

    >>> wpm('hello friend hello buddy hello', 15)
    24.0
    >>> wpm('0123456789',60)
    2.0
    """
def wpm(typed: str, elapsed: float) -> float {
    assert elapsed > 0, 'Elapsed time must be positive';
    return len(typed) / 5 / elapsed * 60;
}