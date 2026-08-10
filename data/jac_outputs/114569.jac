"""
    Generates the first n Fibonacci numbers.
    Adopted from: https://docs.python.org/3/tutorial/modules.html
    """
def fibonacci(n: int) -> list[int] {
    result = [];
    (a, b) = (0, 1);
    while len(result) < n {
        result.append(b);
        (a, b) = (b, a + b);
    }
    return result;
}