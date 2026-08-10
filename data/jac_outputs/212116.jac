"""
    A Pythagorean triplet is a set of three natural numbers, a < b < c, for
    which, a**2 + b**2 = c**2

    For example, 3**2 + 4**2 = 9 + 16 = 25 = 5**2.

    There exists exactly one Pythagorean triplet for which a + b + c = 1000.
    Find the product abc.
    """
def prob9(total: int = 1000) -> int {
    a = 1;
    while True {
        for i in range(2, total) {
            b = i;
            c = total - a - b;
            if a ** 2 + b ** 2 == c ** 2 {
                return a * b * c;
            }
        }
        a += 1;
    }
}