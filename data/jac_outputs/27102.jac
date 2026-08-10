"""
    Args:
        criterion: loss function
        xs: tuple of inputs
        y: ground truth
    """
def DeepSupervision(criterion: Any, xs: Any, y: Any) -> object {
    loss = 0.0;
    for x in xs {
        loss += criterion(x, y);
    }
    return loss;
}