"""Compute the difference between the sum of squares and the square of
    the sum of the natural numbers up to and including the provided ceiling.
    """
def sum_square_difference(ceiling: int) -> int {
    numbers = range(ceiling + 1);
    sum_squares = sum([number ** 2 for number in numbers]);
    square_sum = sum(numbers) ** 2;
    return square_sum - sum_squares;
}