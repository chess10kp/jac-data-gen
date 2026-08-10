"""Get the number of decimal places required to represent a value."""
def get_decimals(value: int | float) -> int {
    val = abs(value);
    fraction = float(val) - int(val);
    if fraction == 0 {
        return 0;
    }
    string = str(val);
    split = string.split('e-');
    if len(split) == 1 {
        return len(string) - split[0].index('.') - 1;
    }
    (number, exponential) = split;
    d = int(exponential);
    if '.' in number {
        return d + len(number) - number.index('.') - 1;
    }
    return d;
}