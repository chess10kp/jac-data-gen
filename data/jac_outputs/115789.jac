"""Annealing learning rate by steps."""
def step_anneal(
    base_lr: float,
    global_step: int,
    anneal_rate: float = 0.98,
    anneal_interval: int = 30000,
    min_lr: float | None = None
) -> float {
    lr = base_lr * anneal_rate ** (global_step // anneal_interval);
    if min_lr is not None {
        lr = max(min_lr, lr);
    }
    return lr;
}