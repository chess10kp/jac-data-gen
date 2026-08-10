"""
    Euclid's Lemma :  d divides a and b, if and only if d divides a-b and b

    Euclid's Algorithm

    Note : In number theory, two integers a and b are said to be relatively prime,
           mutually prime, or co-prime if the only positive integer (factor) that
           divides both of them is 1  i.e., gcd(a,b) = 1.
    """
def greatest_common_divisor(a: int, b: int) -> int {
    if a < b {
        (a, b) = (b, a);
    }
    while a % b != 0 {
        (a, b) = (b, a % b);
    }
    return b;
}