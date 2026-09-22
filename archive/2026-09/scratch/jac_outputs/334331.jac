"""This polynomial was chosen because all of its zeroes (-2, 4, 8) lie in
the x-range we're looking at, so it is quite wiggly"""
def poly_func(X: float) -> float {
    return X ** 3 - 10 * X ** 2 + 8 * X + 64;
}