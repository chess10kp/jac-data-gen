"""Return precision for comparing a value with a double via WF proxy."""
def get_precision(value: int | float | str) -> int {
    sval = '%.2f' % float(value);
    last_index = len(sval);
    found_decimal = False;
    for index in range(len(sval) - 1, 0, -1) {
        char = sval[index];
        last_index = index;
        if char == '.' {
            found_decimal = True;
        }
        if char != '0' and char != '.' {
            break;
        }
    }
    if not found_decimal {
        return last_index - 1;
    }
    return last_index;
}