"""flatten
    flatten 2d array to 1d array
    :param x: initial array
    :return: array after flatten
    """
def flatten(x: Any) -> object {
    x_flatten = [];
    for i in range(len(x)) {
        for j in range(len(x[0])) {
            x_flatten.append(x[i][j]);
        }
    }
    return x_flatten;
}