"""Returns a list of numbers with a certain relation to each other.

    The function divides one number into a list of d numbers [n0, n1, ...], such
    that their sum is number and the relation between the numbers is defined
    with n1 = n0 / r, n2 = n1 / r, n3 = n2 / r, ...
    """
def range_geometric_row(number: Any, d: Any, r: Any = 1.1) -> object {
    if (r <= 0) {
        raise ValueError("r must be > 0");
    }
    n0 = number / ((1 - ((1 / r) ** d)) / (1 - (1 / r)));
    numbers = [n0];
    for i in range((d - 1)) {
        numbers.append((numbers[-1] / r));
    }
    return numbers;
}