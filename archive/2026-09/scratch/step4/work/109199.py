def gaussian_sum(number: int) -> int:
    """
    Gets the sum of all numbers up to the provided number.
    E.g. gaussian_sum(5) == sum([1, 2, 3, 4, 5])
    :param number:
    :return:
    """
    return number * (1 + number) // 2

assert gaussian_sum(11) == 66, "Should be 66"
assert gaussian_sum(10) == sum([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
assert gaussian_sum(6) == 21
assert gaussian_sum(4) == 10, "Should be 10"
assert gaussian_sum(3) == 6, "Should be 6"
assert gaussian_sum(0) == 0
assert gaussian_sum(2) == 3
assert gaussian_sum(-1) == 0
assert gaussian_sum(8) == 36
assert gaussian_sum(15) == 120
assert gaussian_sum(3) == 6
assert gaussian_sum(10) == 55, "Should be 55"
assert gaussian_sum(4) == 10
assert gaussian_sum(5) == sum([1, 2, 3, 4, 5])
assert gaussian_sum(0) == 0, "Should be 0"
assert gaussian_sum(5) == 15
assert gaussian_sum(1) == 1
assert gaussian_sum(100) == 5050
assert gaussian_sum(20) == sum([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
assert gaussian_sum(7) == 28
assert gaussian_sum(20) == 210
assert gaussian_sum(1000) == 500500
assert gaussian_sum(9) == 45
assert gaussian_sum(10) == 55
