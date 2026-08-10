"""Problem 9 - Special Pythagorean triplet."""
def problem9(solution: int) -> int {
    a = 1;
    while a <= solution / 3 {
        b = a + 1;
        while b <= solution / 2 {
            c = solution - (a + b);
            if c <= b {
                break;
            }
            if (a * a) + (b * b) == c * c {
                return a * b * c;
            }
            b += 1;
        }
        a += 1;
    }
    return -1;
}