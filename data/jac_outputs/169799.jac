"""
    >>> has_a_double_not_in_larger_group('1234')
    False
    >>> has_a_double_not_in_larger_group('111123')
    False
    >>> has_a_double_not_in_larger_group('135679')
    False
    >>> has_a_double_not_in_larger_group('223450')
    True
    >>> has_a_double_not_in_larger_group('111111')
    False
    >>> has_a_double_not_in_larger_group('123789')
    False
    >>> has_a_double_not_in_larger_group('112233')
    True
    >>> has_a_double_not_in_larger_group('123444')
    False
    >>> has_a_double_not_in_larger_group('111122')
    True
    """
def has_a_double_not_in_larger_group(s: Any) -> object {
    l = [int(c) for c in s];
    while (len(l) > 0) {
        current_l = [];
        current_l.append(l.pop(0));
        while (len(l) > 0) {
            if (l[0] == current_l[0]) {
                current_l.append(l.pop(0));
            } else {
                break;
            }
        }
        if (len(current_l) == 2) {
            return True;
        }
    }
    return False;
}