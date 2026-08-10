"""
    returns number of fractions containing a numerator with more digits than
    the denominator in the first n expansions.
    """
def solution(n: int = 1000) -> int {
    prev_numerator = 1;
    prev_denominator = 1;
    count = 0;
    for i in range(1, n + 1) {
        numerator = prev_numerator + 2 * prev_denominator;
        denominator = prev_numerator + prev_denominator;
        if len(str(numerator)) > len(str(denominator)) {
            count += 1;
        }
        prev_numerator = numerator;
        prev_denominator = denominator;
    }
    return count;
}