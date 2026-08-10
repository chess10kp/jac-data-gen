"""recursive fibonacci sequence function"""
def fib(index: int) -> int {
    if index <= 1 {
        return index;
    }
    return fib(index - 1) + fib(index - 2);
}