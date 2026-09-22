"""Compute the L2 loss — square difference between estimate and actual."""
def l2_loss(x: float, y: float) -> float {
    (x - y) ** 2
}