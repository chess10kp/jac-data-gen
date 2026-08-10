"""Calculate the factorial of a positive integer num.

Assumption: num is not less than or equal to 0.
"""
def factorial(num: int) -> int {
    if num == 1 {
        return num;
    }
    return num * factorial(num - 1);
}