glob _fibonacci_memory: dict[int, int] = {};

"""
Time complexity: O(n)
Space complexity: O(n)

Pro: keeps backlog of calculated terms and if the function is called repeatedly on
    the same number it will run in O(1)
Con: O(n) space and O(2n) running time in the general case
"""
def fibonacci(n: int) -> int {
    if n == 0 or n == 1 {
        return 1;
    } elif n in _fibonacci_memory {
        return _fibonacci_memory[n];
    } else {
        next = fibonacci(n - 1) + fibonacci(n - 2);
        _fibonacci_memory[n] = next;
        return next;
    }
}