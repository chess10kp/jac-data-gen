def count_digits_recursion(number: int) -> int:
    """
    >>> count_digits_recursion(-123)
    3
    >>> count_digits_recursion(-1)
    1
    >>> count_digits_recursion(0)
    1
    >>> count_digits_recursion(123)
    3
    >>> count_digits_recursion(123456)
    6
    """
    number = abs(number)
    return 1 if number < 10 else 1 + count_digits_recursion(number // 10)

assert count_digits_recursion(10000) == 5
assert count_digits_recursion(99) == 2
assert count_digits_recursion(12345678) == 8
assert count_digits_recursion(-12345) == 5
assert count_digits_recursion(-123) == 3
assert count_digits_recursion(100000) == 6
assert count_digits_recursion(0) == 1
assert count_digits_recursion(1) == 1
assert count_digits_recursion(-1234567) == 7
assert count_digits_recursion(-123456789) == 9
assert count_digits_recursion(-12345678) == 8
assert count_digits_recursion(12345678901234567890) == 20
assert count_digits_recursion(100) == 3
assert count_digits_recursion(10000000) == 8
assert count_digits_recursion(1000) == 4
assert count_digits_recursion(11) == 2
assert count_digits_recursion(123) == 3
assert count_digits_recursion(100000000) == 9
assert count_digits_recursion(1000000) == 7
assert count_digits_recursion(-1000000) == 7
assert count_digits_recursion(-10000) == 5
assert count_digits_recursion(-10) == 2
assert count_digits_recursion(123456789) == 9
assert count_digits_recursion(1234567890) == 10
assert count_digits_recursion(12) == 2
assert count_digits_recursion(9) == 1
assert count_digits_recursion(1234) == 4
assert count_digits_recursion(-123456) == 6
assert count_digits_recursion(10) == 2
assert count_digits_recursion(123456) == 6
assert count_digits_recursion(-1) == 1
assert count_digits_recursion(12345) == 5
assert count_digits_recursion(-1000) == 4
assert count_digits_recursion(1234567) == 7
assert count_digits_recursion(-123) == count_digits_recursion(-123)
assert count_digits_recursion(-12) == 2
assert count_digits_recursion(987654321) == 9
assert count_digits_recursion(-1234) == 4
assert count_digits_recursion(-100000) == 6
assert count_digits_recursion(-100) == 3
