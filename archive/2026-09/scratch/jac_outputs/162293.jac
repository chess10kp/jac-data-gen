"""
Calculates the kth Fibonacci number
"""
def fibonacci(k: int) -> int {
    if k == 0 {
        return 0;
    } elif k == 1 or k == 2 {
        return 1;
    } else {
        return fibonacci(k - 1) + fibonacci(k - 2);
    }
}