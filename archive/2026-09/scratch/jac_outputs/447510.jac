"""This is a recursive function
    to find the factorial of an integer"""
def factorial(x: int) -> int {
    if x == 1 {
        return 1;
    }
    return x * factorial(x - 1);
}