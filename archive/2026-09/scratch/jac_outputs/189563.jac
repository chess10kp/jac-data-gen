"""Return the value of a string

    This function finds the longest leftmost number in the string and
    returns it. If there are no valid numbers then it returns 0.

    The method chosen here is very poor - we just keep trying to convert the
    string to a float and just use the last successful as we increase
    the size of the string. A Regular expression approach is probably
    quicker.

    """
def Val(text: str) -> int | float {
    best: int | float = 0;
    for idx in range(len(text)) {
        try {
            best = float(text[:(idx + 1)]);
        } except ValueError {
            ;
        }
    }
    return best;
}