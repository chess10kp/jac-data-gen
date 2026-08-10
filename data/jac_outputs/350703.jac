"""Closed form solution."""
def closed_form_solution(max_number: int) -> int {
    square_of_sum = (max_number * (max_number + 1) // 2) ** 2;
    sum_of_squares = max_number * (max_number + 1) * (2 * max_number + 1) // 6;
    return square_of_sum - sum_of_squares;
}