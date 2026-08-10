"""Scale loss by loss_scale."""
def scale_loss(loss: float | Callable[[], float], loss_scale: float) -> float | Callable[[], float] {
    if callable(loss) {
        loss_fn: Callable[[], float] = loss;
        return lambda() { loss_fn() * loss_scale; };
    }
    return loss * loss_scale;
}