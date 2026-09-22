"""Exponential out. :math:`f(t) = 2^t`"""
def exp_out(t: Any) -> object {
    return (1 - pow(2, (-10 * t)));
}