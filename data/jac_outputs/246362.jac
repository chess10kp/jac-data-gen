"""Update the value of `x` by adding `increment`.

    # Arguments
        x: A `Variable`.
        increment: A tensor of same shape as `x`.

    # Returns
        The variable `x` updated.
    """
def update_add(x: int, increment: int) -> tuple[int, int] {
    return (x, x + increment);
}