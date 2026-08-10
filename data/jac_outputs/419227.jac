"""For debugging purposes, use this instead of jax.lax.cond."""
def flax_cond[T, R](
    pred: bool,
    true_operand: T,
    true_fun: Callable[[T], R],
    false_operand: T,
    false_fun: Callable[[T], R]
) -> R {
    if pred {
        return true_fun(true_operand);
    }
    return false_fun(false_operand);
}