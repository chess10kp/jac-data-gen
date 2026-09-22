"""
    Change the 2 provided numbers into a number of microseconds.
    Examples inputs:
        "100", "us"
        "2.76", "ms"
        "3", "s"
    """
def str_to_microsec(str_1: str, str_2: str) -> float {
    if str_2 == "us" {
        k = 1.0;
    } elif str_2 == "ms" {
        k = 1000.0;
    } elif str_2 == "s" {
        k = 1000000.0;
    } else {
        raise ValueError('Unrecognized time format: {:}.'.format(str_2));
    }
    return float(str_1) * k;
}