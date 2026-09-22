def contains_only_char(s, char):
    """ Check whether a str contains only one kind of chars

    :param s: str, the string for checking
    :param char: str, the char for checking
    :return:
    """
    for c in s:
        if c != char:
            return False
    return True

assert contains_only_char("abcd", "g") == False
assert contains_only_char("xx", None) == False
assert contains_only_char(
    "23451", "2"
) == False
assert contains_only_char( 'ab', 'a' ) == False
assert contains_only_char("xx", "") == False
assert contains_only_char( 'ab', 'c' ) == False
assert contains_only_char('', '') == True
assert contains_only_char("xx", "z") == False
assert contains_only_char("abcd", "j") == False
assert contains_only_char(
    "hello", "x") == False
assert contains_only_char("xx", None) == False
assert contains_only_char("xx", "") == False
assert contains_only_char('1234567890', 'a') == False
assert contains_only_char('1234567890', '1') == False
assert contains_only_char("abcd", 6) == False
assert contains_only_char("abcd", "f") == False
assert contains_only_char( 'abc', '' ) == False
assert contains_only_char("a", "b") == False
assert contains_only_char("xx", 0) == False
assert contains_only_char("abcd", "k") == False
assert contains_only_char("abcd", 0) == False
assert contains_only_char('aaa', 'a') == True
assert contains_only_char("abcd", "m") == False
assert contains_only_char('a', 'a') == True
assert contains_only_char("x", "x") == True
assert contains_only_char('aaaaaa', 'b') == False
assert contains_only_char('1234567890','') == False
assert contains_only_char(" ", " ") == True
assert contains_only_char("x", "x") == True
assert contains_only_char("abcd", 2) == False
assert contains_only_char("abcd", "o") == False
assert contains_only_char("a", "a") == True
assert contains_only_char("xx", 0) == False
assert contains_only_char("xx", " ") == False
assert contains_only_char("abcd", 7) == False
assert contains_only_char("abcd", 9) == False
assert contains_only_char("abcd", "h") == False
assert contains_only_char( 'abc', 'a' ) == False
assert contains_only_char("xx", "z") == False
assert contains_only_char(
    "aaaa", "a"
) == True
assert contains_only_char( 'abc', 'ab' ) == False
assert contains_only_char('a', '1') == False
assert contains_only_char("abcd", "c") == False
assert contains_only_char('ababa', 'c') == False
assert contains_only_char("abcd", "e") == False
assert contains_only_char('aaaa', 'a') == True
assert contains_only_char( 'a', 'a' ) == True
assert contains_only_char("abcd", 5) == False
assert contains_only_char("abcd", "l") == False
assert contains_only_char("abcd", "d") == False
assert contains_only_char('111111', '1') == True
assert contains_only_char("abcd", "i") == False
assert contains_only_char(
    "ababab", "a"
) == False
assert contains_only_char("xx", " ") == False
assert contains_only_char('12345', 1) == False
assert contains_only_char('12345', 'a') == False
assert contains_only_char("abcd", "n") == False
assert contains_only_char("abcd", 3) == False
assert contains_only_char("abcd", "a") == False
assert contains_only_char('bbb', 'a') == False
