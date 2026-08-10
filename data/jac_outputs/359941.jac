""" Poly_LR scheduler
    """
def lr_poly(base_lr: Any, i_iter: Any, max_iters: Any, power: Any) -> object {
    return (base_lr * ((1 - (float(i_iter) / max_iters)) ** power));
}