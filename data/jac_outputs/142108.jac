"""
    Is the size of FFT such that FFTPACK can handle it in single precision
    with sufficient accuracy?

    Composite numbers of 2, 3, and 5 are accepted, as FFTPACK has those
    """
def _is_safe_size(n: int | float | str) -> bool {
    n = int(n);
    for c in (2, 3, 5) {
        while n % c == 0 {
            n /= c;
        }
    }
    n <= 1
}