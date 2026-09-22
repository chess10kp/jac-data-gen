"""
Given two lists or arrays x and y, linearly interpolates between adjacent
x-values to give an estimated y-value for any particular x.
"""
def linear_interpolate(x: list[float], y: list[float], x_desired: float) -> float {
    index = 0;
    while x[index] <= x_desired {
        index = index + 1;
    }
    x_left = x[index - 1];
    x_right = x[index];
    return (
        (y[index - 1] * (x_right - x_desired) + y[index] * (x_desired - x_left))
        / (x_right - x_left)
    );
}