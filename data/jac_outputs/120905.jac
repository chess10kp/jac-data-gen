"""Return the n-th Fibonacci number."""
def fibonacci(n_terms: int) -> int {
    if n_terms <= 1 {
        return n_terms;
    }
    return fibonacci(n_terms - 1) + fibonacci(n_terms - 2);
}