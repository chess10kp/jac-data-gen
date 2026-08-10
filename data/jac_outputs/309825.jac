"""Calculate fibonacci numbers."""
def sample_fib(x: int) -> int {
    if x == 0 or x == 1 {
        return 1;
    }
    return sample_fib(x - 1) + sample_fib(x - 2);
}