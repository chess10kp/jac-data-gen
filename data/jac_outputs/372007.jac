"""Score substitution of two characters.

    Args:
      a_c1 (str): first word to compare
      a_c2 (str): second word to compare

    Returns:
      int: 2 if the last characters of both words are equal, -3 otherwise

    """
def score_substitute(a_c1: Any, a_c2: Any) -> object {
    return 2 if (a_c1[-1] == a_c2[-1]) else -3;
}