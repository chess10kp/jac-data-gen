""" (number, number, numbern number) -> number

    Precondition: 100 > Numbers > 0.

    Returns the average of the highest three numbers.

    >>>average(40, 99, 87, 0)
    75.33
    >>>average(80, 10, 100, 40)
    73.33

    """
def best3av(a: Any, b: Any, c: Any, d: Any) -> object {
    One = min(a, b, c, d);
    Two = (a + b + c + d) - One;
    Three = Two / 3;
    return round(Three, 2);
}