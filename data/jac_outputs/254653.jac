"""
    Return modular inverse using a version Euclid's Algorithm
    Code by Andrew Kuchling in Python Journal:
    http://www.pythonjournal.com/volume1/issue1/art-algorithms/
    -- in turn also based on Knuth, vol 2.
    """
def invmod(a: int, b: int) -> int {
    (a1, a2, a3) = (1, 0, a);
    (b1, b2, b3) = (0, 1, b);
    while b3 != 0 {
        q = a3 / b3;
        t = (a1 - b1 * q, a2 - b2 * q, a3 - b3 * q);
        (a1, a2, a3) = (b1, b2, b3);
        (b1, b2, b3) = t;
    }
    while a2 < 0 {
        a2 = a2 + a;
    }
    return a2;
}