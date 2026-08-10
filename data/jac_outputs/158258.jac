"""
Interpolation of a single point by the Lagrange method.
"""
def point_interpolation(
    x_array: list[int] | list[float],
    fx_array: list[int] | list[float],
    nStart: int,
    nStop: int,
    x: int | float
) -> int | float {
    number_type = `type(x_array[0]) if x_array else `type(fx_array[0]) if fx_array else `type(x);
    ntResult = number_type(0);
    for i in range(nStart, nStop) {
        ntProduct = fx_array[i];
        for j in range(nStart, i) {
            ntProduct *= (x - x_array[j]) / (x_array[i] - x_array[j]);
        }
        for j in range(i + 1, nStop) {
            ntProduct *= (x - x_array[j]) / (x_array[i] - x_array[j]);
        }
        ntResult += ntProduct;
    }
    return ntResult;
}