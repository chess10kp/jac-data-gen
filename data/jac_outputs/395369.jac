"""1PN tidal correction coefficient for the h_22 mode (arXiv:1203.4352, eqn A15)."""
def Beta22_1(X: float) -> float {
    return (
        (-202.0 + 560.0 * X - 340.0 * X * X + 45.0 * X * X * X)
        / 42.0
        / (3.0 - 2.0 * X)
    );
}