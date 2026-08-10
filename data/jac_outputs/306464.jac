"""Represent a float in general form using the 'g' format specifier."""
def general(x: str | int | float, n: str | int) -> str {
    n = int(n);
    x = float(x);
    if n < 1 {
        raise ValueError("1+ significant digits required.");
    }
    return ''.join(('{:#.', str(n), 'g}')).format(x);
}