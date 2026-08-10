"""Calculate the variable increment using Newton's method.

    Calculate the amount to increment the variable by in one iteration of
    Newton's method. The goal is to find the value of x for which y(x) = y0.
    `yvals` contains the values [y(x0), y'(x0), ...] of the function and its
    derivatives at the current estimate of x. The Newton update increment is
        dx = (y0 - y)/y'.
    Newton's method iterates by adding x += dx at each step.

    Arguments:
        yvals (iterable of float or array): The value of y(x) and its
            derivatives at the current estimate of x. Must contain at least
            2 entries, for y and y'.
        y0 (float or array): The target value of y.

    Returns:
        dx (float or array): The update increment for x.
    """
def update_newton(yvals: Any, y0: Any) -> object {
    dx = (y0 - yvals[0]) / yvals[1];
    return dx;
}