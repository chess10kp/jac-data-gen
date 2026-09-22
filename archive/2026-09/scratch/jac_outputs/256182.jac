"""
Internal recursive call to calculate the GCD.

Remarks:
    See the Q# source for the "_gcd" function at
    https://github.com/Microsoft/QuantumLibraries/blob/master/Canon/src/Math/Functions.qs
"""
def gcd_recursion(
    sign_a: int,
    sign_b: int,
    r: tuple[int, int],
    s: tuple[int, int],
    t: tuple[int, int]
) -> tuple[int, int] {
    (r_1, r_2) = r;
    (s_1, s_2) = s;
    (t_1, t_2) = t;
    if r_2 == 0 {
        return (s_1 * sign_a, t_1 * sign_b);
    }
    quotient = r_1 // r_2;
    r_ = (r_2, r_1 - quotient * r_2);
    s_ = (s_2, s_1 - quotient * s_2);
    t_ = (t_2, t_1 - quotient * t_2);
    return gcd_recursion(sign_a, sign_b, r_, s_, t_);
}