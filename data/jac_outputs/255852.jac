"""Return the prefix applied to variable names in Stata e(b), e(V) matrices."""
def stata_operator(leadlag: int | float | str, level: int | float | str) -> str {
    leadlag = int(leadlag);
    match leadlag {
        case 0:
            ll = '';
        case 1:
            ll = 'L';
        case -1:
            ll = 'F';
        case _ if leadlag > 1:
            ll = 'L' + str(leadlag);
        case _:
            ll = 'F' + str(abs(leadlag));
    }
    if int(level) < 0 {
        raise ValueError('Negative factor levels are not allowed.');
    }
    lv = str(level);
    op = lv + ll;
    return op + '.' if op != '' else op;
}