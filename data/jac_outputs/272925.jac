"""Function takes an integer and returns an integer."""
def square_digits(num: int) -> int {
    return int(''.join(map(str, [(int(x) ** 2) for x in list(str(num))])));
}