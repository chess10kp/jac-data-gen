"""
    Author: Zakaria Ismail

    RETURNS the sum of three numbers
    PASSED. If sum exceeds 255, then
    the sum is 255.

    >> compute_sum(5,6,7)
    18
    """
def compute_sum(r: int, g: int, b: int) -> int {
    return r + g + b if r + g + b <= 255 else 255;
}