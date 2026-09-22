"""
    l2 regularization proximity operator (ridge)

    x : vector to project
    lambd: reg
    """
def prox_l2(x: Any, lambd: Any = 1, **kwargs: Any) -> object {
    return (x / (1 + lambd));
}