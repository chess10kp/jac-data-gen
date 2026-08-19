def square(x: int) -> int {
    # native ints are fixed-width 64-bit, so guard the range where x * x overflows
    if x > 3037000499 or x < -3037000499 {
        raise ValueError("square: |x| too large, x * x would overflow a 64-bit native int");
    }
    return x * x;
}
