"""
Formats an ordinal.
Doesn't handle negative numbers.
"""
def int_nthstr(n: int) -> str {
    assert n >= 0;
    if n % 100 in [11, 12, 13] {
        return '%sth' % n;
    }
    match n % 10 {
        case 1:
            return '%sst' % n;
        case 2:
            return '%snd' % n;
        case 3:
            return '%srd' % n;
        case _:
            return '%sth' % n;
    }
}