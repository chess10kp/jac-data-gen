"""Make a string with comma separated dice values from tuple."""
def make_dices(tup: tuple[int, ...] | str | tuple[float, ...]) -> str {
    if not (`type(tup) == tuple) {
        raise TypeError('Only tuples allowed, not ' + str(`type(tup)));
    }
    for number in tup {
        if not (`type(number) == int) {
            raise TypeError('Only integer values allowed, not ' + str(number));
        }
        if number < 1 or number > 6 {
            raise ValueError(f'Only values between 1 and 6 allowed, not {number:d}');
        }
    }
    return ','.join(str(number) for number in tup);
}