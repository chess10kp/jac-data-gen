"""Shake-shake regularization in testing mode: 50/50 blend of branches A and B."""
def shake_shake_eval(xa: float, xb: float) -> float {
    return (xa + xb) * 0.5;
}