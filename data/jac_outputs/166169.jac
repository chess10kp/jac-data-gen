"""
    https://en.wikipedia.org/wiki/Hamming_distance#Algorithm_example
    Return the Hamming distance between equal-length sequences
    """
def hamming_distance(s1: str, s2: str) -> int {
    if len(s1) != len(s2) {
        raise ValueError("Undefined for sequences of unequal length");
    }
    s1 = ''.join("{0:08b}".format(ord(c)) for c in s1);
    s2 = ''.join("{0:08b}".format(ord(c)) for c in s2);
    return sum(el1 != el2 for (el1, el2) in zip(s1, s2));
}