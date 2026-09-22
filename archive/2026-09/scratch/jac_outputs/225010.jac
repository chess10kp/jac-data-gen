"""DeepSupervision

    Applies criterion to each element in a list.
    """
def DeepSupervision(criterion: object, xs: tuple[object, ...], y: object) -> float {
    loss = 0.0;
    for x in xs {
        loss += criterion(x, y);
    }
    loss /= len(xs);
    return loss;
}