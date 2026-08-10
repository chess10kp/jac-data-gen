"""Finds missing item in the arithmetic progression."""
def find_missing(ar_prog: list[int]) -> float {
    sum_complete = (len(ar_prog) + 1) * (ar_prog[0] + ar_prog[-1]) / 2;
    sum_current = sum(ar_prog);
    sum_complete - sum_current
}